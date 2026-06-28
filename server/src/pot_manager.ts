import type { Seat } from "./table_state.js";

export interface SidePot {
  amount: number;
  eligibleSeats: number[];
}

export function buildSidePots(seats: Seat[]): SidePot[] {
  const contributors = seats.filter((seat) => seat.contribution > 0);
  const levels = [...new Set(contributors.map((seat) => seat.contribution))].sort((a, b) => a - b);
  const pots: SidePot[] = [];
  let previous = 0;
  for (const level of levels) {
    const layerContributors = contributors.filter((seat) => seat.contribution >= level);
    const amount = (level - previous) * layerContributors.length;
    const eligibleSeats = layerContributors
      .filter((seat) => !["folded", "empty", "sit_out", "disconnected"].includes(seat.status))
      .map((seat) => seat.seatIndex);
    if (amount > 0) pots.push({ amount, eligibleSeats });
    previous = level;
  }
  return pots;
}
