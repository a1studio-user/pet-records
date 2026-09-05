import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const jsonHeaders = { "Content-Type": "application/json; charset=utf-8" };

function json(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

Deno.serve(async (request: Request) => {
  if (request.method !== "POST") {
    return json(405, { error: "仅支持 POST 请求。" });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json(401, { error: "登录状态已失效，请重新登录。" });
  }

  const projectURL = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!projectURL || !publishableKey || !serviceRoleKey) {
    return json(500, { error: "服务端配置不完整。" });
  }

  const userClient = createClient(projectURL, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const admin = createClient(projectURL, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) {
    return json(401, { error: "登录状态已失效，请重新登录。" });
  }

  const userID = userData.user.id;
  const requestBody = await request.json().catch(() => ({})) as Record<string, unknown>;
  const appleAuthorizationCode = requestBody.apple_authorization_code;
  if (typeof appleAuthorizationCode !== "string" || appleAuthorizationCode.length === 0) {
    return json(400, { error: "请重新通过 Apple 确认后再删除账号。" });
  }

  const appleTeamID = Deno.env.get("APPLE_TEAM_ID");
  const appleClientID = Deno.env.get("APPLE_CLIENT_ID");
  const appleKeyID = Deno.env.get("APPLE_KEY_ID");
  const applePrivateKey = Deno.env.get("APPLE_PRIVATE_KEY");
  if (!appleTeamID || !appleClientID || !appleKeyID || !applePrivateKey) {
    return json(500, { error: "Apple 账号删除配置不完整，请联系开发者。" });
  }

  const clientSecret = await createAppleClientSecret({
    teamID: appleTeamID,
    clientID: appleClientID,
    keyID: appleKeyID,
    privateKey: applePrivateKey,
  });
  const tokenExchange = await postAppleForm("https://appleid.apple.com/auth/token", {
    client_id: appleClientID,
    client_secret: clientSecret,
    code: appleAuthorizationCode,
    grant_type: "authorization_code",
  });
  if (!tokenExchange.response.ok) {
    return json(502, { error: "无法确认 Apple 账号，请重新登录后再试。" });
  }

  const appleSubject = jwtSubject(tokenExchange.body.id_token);
  const linkedAppleSubject = userData.user.identities
    ?.find((identity) => identity.provider === "apple")
    ?.identity_data?.sub;
  if (!appleSubject || typeof linkedAppleSubject !== "string" || appleSubject !== linkedAppleSubject) {
    return json(403, { error: "确认的 Apple 账号与当前账号不一致。" });
  }

  const revocationToken = tokenExchange.body.refresh_token ?? tokenExchange.body.access_token;
  if (typeof revocationToken !== "string" || revocationToken.length === 0) {
    return json(502, { error: "Apple 未返回可撤销的登录凭据，请重试。" });
  }
  const revocation = await postAppleForm("https://appleid.apple.com/auth/revoke", {
    client_id: appleClientID,
    client_secret: clientSecret,
    token: revocationToken,
    token_type_hint: tokenExchange.body.refresh_token ? "refresh_token" : "access_token",
  });
  if (!revocation.response.ok) {
    return json(502, { error: "无法撤销 Apple 登录凭据，账号尚未删除，请稍后重试。" });
  }

  const { data: ownedPets, error: petError } = await admin
    .from("pets")
    .select("id")
    .eq("user_id", userID);
  if (petError) {
    return json(500, { error: "读取账号数据失败，请稍后重试。" });
  }

  // Remove every object uploaded by this account. Objects belonging to pets
  // owned by the account are removed by the cleanup function below, including
  // files uploaded by caregivers.
  try {
    const paths = new Set(await listFilesRecursively(admin, userID));
    const ownedPetIDs = (ownedPets ?? []).map((pet) => pet.id as string);
    if (ownedPetIDs.length > 0) {
      for (const uploaderID of await listDirectories(admin, "")) {
        for (const petID of ownedPetIDs) {
          for (const path of await listFilesRecursively(admin, `${uploaderID}/${petID}`)) {
            paths.add(path);
          }
        }
      }
    }
    await removeFiles(admin, [...paths]);
  } catch {
    return json(500, { error: "删除账号照片失败，请稍后重试。" });
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(userID);
  if (deleteError) {
    return json(500, { error: "删除账号失败，请稍后重试。" });
  }

  return json(200, { deleted: true });
});

type AppleClientSecretConfiguration = {
  teamID: string;
  clientID: string;
  keyID: string;
  privateKey: string;
};

async function createAppleClientSecret(configuration: AppleClientSecretConfiguration): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64URL(JSON.stringify({ alg: "ES256", kid: configuration.keyID, typ: "JWT" }));
  const claims = base64URL(JSON.stringify({
    iss: configuration.teamID,
    iat: now,
    exp: now + 300,
    aud: "https://appleid.apple.com",
    sub: configuration.clientID,
  }));
  const signingInput = `${header}.${claims}`;
  const privateKey = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(configuration.privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    new TextEncoder().encode(signingInput),
  );
  return `${signingInput}.${base64URL(new Uint8Array(signature))}`;
}

async function postAppleForm(url: string, values: Record<string, string>) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(values),
  });
  const body = await response.json().catch(() => ({})) as Record<string, unknown>;
  return { response, body };
}

function jwtSubject(token: unknown): string | null {
  if (typeof token !== "string") return null;
  const parts = token.split(".");
  if (parts.length < 2) return null;
  try {
    const payload = JSON.parse(new TextDecoder().decode(base64URLToBytes(parts[1])));
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

function pemToBytes(pem: string): Uint8Array {
  const normalized = pem.replaceAll("\\n", "\n");
  const value = normalized
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replaceAll(/\s/g, "");
  return Uint8Array.from(atob(value), (character) => character.charCodeAt(0));
}

function base64URL(value: string | Uint8Array): string {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
}

function base64URLToBytes(value: string): Uint8Array {
  const normalized = value.replaceAll("-", "+").replaceAll("_", "/");
  const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
  return Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
}

async function listFilesRecursively(
  admin: ReturnType<typeof createClient>,
  prefix: string,
): Promise<string[]> {
  const files: string[] = [];
  const pending = [prefix];

  while (pending.length > 0) {
    const directory = pending.pop()!;
    let offset = 0;
    while (true) {
      const { data, error } = await admin.storage.from("pet-media").list(directory, {
        limit: 100,
        offset,
        sortBy: { column: "name", order: "asc" },
      });
      if (error) throw error;
      const entries = data ?? [];
      for (const entry of entries) {
        const path = `${directory}/${entry.name}`;
        if (entry.id == null) pending.push(path);
        else files.push(path);
      }
      if (entries.length < 100) break;
      offset += entries.length;
    }
  }

  return files;
}

async function listDirectories(
  admin: ReturnType<typeof createClient>,
  prefix: string,
): Promise<string[]> {
  const directories: string[] = [];
  let offset = 0;
  while (true) {
    const { data, error } = await admin.storage.from("pet-media").list(prefix, {
      limit: 100,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) throw error;
    const entries = data ?? [];
    directories.push(...entries.filter((entry) => entry.id == null).map((entry) => entry.name));
    if (entries.length < 100) break;
    offset += entries.length;
  }
  return directories;
}

async function removeFiles(
  admin: ReturnType<typeof createClient>,
  paths: string[],
): Promise<void> {
  for (let start = 0; start < paths.length; start += 100) {
    const { error } = await admin.storage.from("pet-media").remove(paths.slice(start, start + 100));
    if (error) throw error;
  }
}
