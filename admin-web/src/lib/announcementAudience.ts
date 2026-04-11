import { audienceOptions } from "../data/mockData";

export type AudienceOption = (typeof audienceOptions)[number];

/** Mirrors `RegisterScreen` / compose mapping in the Flutter app. */
export function mapAudienceToTargetRole(audience: AudienceOption): string {
  if (audience === "Students Only") return "student";
  if (audience === "Staff Only") return "staff";
  return "all";
}
