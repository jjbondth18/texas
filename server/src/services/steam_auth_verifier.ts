export interface SteamAuthVerificationResult {
  valid: boolean;
  steam_id?: string;
  app_id?: string;
  error_code?: string;
}

export interface SteamAuthVerifier {
  verifyTicket(ticketHex: string, appId: string, expectedIdentity: string): SteamAuthVerificationResult;
}

export class SteamWebApiAuthVerifier implements SteamAuthVerifier {
  constructor(private readonly publisherKey: string) {}

  verifyTicket(ticketHex: string, appId: string, _expectedIdentity: string): SteamAuthVerificationResult {
    if (!isLikelyHex(ticketHex)) return { valid: false, error_code: "steam_ticket_invalid" };
    if (this.publisherKey.trim() === "" || appId.trim() === "") return { valid: false, error_code: "steam_verifier_not_configured" };
    // Scaffold only: the authoritative Web API call to
    // ISteamUserAuth/AuthenticateUserTicket will be wired once the real AppID
    // and Publisher Web API key are available. RoomManager supports injection
    // of a verifier for tests and future production integration.
    return { valid: false, error_code: "steam_verifier_not_configured" };
  }
}

function isLikelyHex(value: string): boolean {
  return value.length > 0 && value.length % 2 === 0 && /^[0-9a-fA-F]+$/.test(value);
}
