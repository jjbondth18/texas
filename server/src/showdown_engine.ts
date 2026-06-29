import { compareEvaluations, evaluateBestHand, type HandEvaluation } from "./hand_evaluator.js";
import type { Seat, TableState } from "./table_state.js";

export function settleHand(table: TableState): void {
  if (table.phase === "hand_over") return;
  const live = table.liveSeats();
  if (live.length > 1) {
    table.runoutBoard();
    if (table.phase !== "showdown") {
      table.phase = "showdown";
      table.addAction({ type: "phase", action: "showdown", message: "Showdown." });
    }
  }

  const evaluations = new Map<number, HandEvaluation>();
  for (const seat of live) {
    if (table.communityCards.length >= 5) {
      evaluations.set(seat.seatIndex, evaluateBestHand([...seat.holeCards, ...table.communityCards]));
    }
  }

  const awards = new Map<number, number>();
  const records = new Map<number, { handRank?: string; cards?: string[] }>();
  for (const pot of table.sidePots()) {
    const eligible = pot.eligibleSeats.map((seatIndex) => table.getSeat(seatIndex)).filter((seat): seat is Seat => Boolean(seat));
    const winners = bestSeats(eligible, evaluations);
    if (winners.length === 0) continue;
    const share = Math.floor(pot.amount / winners.length);
    let odd = pot.amount % winners.length;
    for (const winner of winners) {
      const bonus = odd > 0 ? 1 : 0;
      odd -= bonus;
      awards.set(winner.seatIndex, (awards.get(winner.seatIndex) ?? 0) + share + bonus);
      const evaluation = evaluations.get(winner.seatIndex);
      if (evaluation) records.set(winner.seatIndex, { handRank: evaluation.rank, cards: evaluation.cards });
    }
  }

  table.winners = [];
  const awardsBySeat = new Map(awards);
  for (const [seatIndex, amount] of awards) {
    const seat = table.getSeat(seatIndex);
    if (!seat) continue;
    seat.chips += amount;
    const record = records.get(seatIndex) ?? {};
    table.winners.push({ seat_index: seatIndex, amount, hand_rank: record.handRank, cards: record.cards });
    table.addAction({
      type: "winner",
      seat_id: seatIndex,
      seat_index: seatIndex,
      player_name: seat.name,
      action: "win",
      amount,
      message: `${seat.name} wins ${amount}${record.handRank ? ` with ${record.handRank}` : ""}.`,
    });
  }
  table.lastHandResults = table.seats
    .filter((seat) => seat.playerId && table.handStartChipCount(seat.seatIndex) !== undefined)
    .map((seat) => {
      const before = table.handStartChipCount(seat.seatIndex) ?? seat.chips;
      return {
        seat_index: seat.seatIndex,
        player_name: seat.name,
        before_chips: before,
        after_chips: seat.chips,
        delta: seat.chips - before,
        award: awardsBySeat.get(seat.seatIndex) ?? 0,
      };
    });
  for (const result of table.lastHandResults) {
    const sign = result.delta >= 0 ? "+" : "";
    table.addAction({
      type: "system",
      message: `${result.player_name} stack ${result.before_chips} -> ${result.after_chips} (${sign}${result.delta}).`,
    });
  }
  for (const seat of table.seats) {
    seat.currentBet = 0;
    seat.contribution = 0;
    seat.acted = false;
    if (seat.status === "playing" || seat.status === "folded" || seat.status === "all_in") {
      seat.status = seat.chips > 0 ? "sitting" : "sit_out";
    }
  }
  table.phase = "hand_over";
  table.currentBet = 0;
  table.currentTurnSeat = -1;
  table.finishDisconnectedHand();
  table.addAction({ type: "system", message: `Hand ${table.handId} settled.` });
}

function bestSeats(seats: Seat[], evaluations: Map<number, HandEvaluation>): Seat[] {
  if (seats.length <= 1) return seats;
  let best: HandEvaluation | null = null;
  let winners: Seat[] = [];
  for (const seat of seats) {
    const evaluation = evaluations.get(seat.seatIndex);
    if (!evaluation) continue;
    const cmp = best ? compareEvaluations(evaluation, best) : 1;
    if (cmp > 0) {
      best = evaluation;
      winners = [seat];
    } else if (cmp === 0) {
      winners.push(seat);
    }
  }
  return winners;
}
