import type { PrivateSnapshot } from "./protocol.js";
import type { Seat, TableState } from "./table_state.js";
import type {
  PublicPokerAction,
  VirtualAction,
  VirtualBotContext,
  VirtualPosition,
  VirtualStreet,
} from "./virtual_player_ai/virtual_ai_types.js";

export interface VirtualBotContextSource {
  botPlayerId: string;
  table: TableState;
  seatCount: number;
  legalActions: PrivateSnapshot["legal_actions"];
  handIndex: number;
  decisionIndex: number;
  sessionSeed: string;
}

const STREETS = new Set<VirtualStreet>(["preflop", "flop", "turn", "river"]);
const ACTIONS = new Set<VirtualAction>(["fold", "check", "call", "raise", "all_in"]);

export function buildVirtualBotContext(source: VirtualBotContextSource): VirtualBotContext {
  const { table } = source;
  if (!STREETS.has(table.phase as VirtualStreet)) throw new Error("virtual_context_invalid_street");
  const bot = table.getSeatByPlayer(source.botPlayerId);
  if (!bot) throw new Error("virtual_context_bot_not_seated");
  const participants = handParticipants(table);
  const stillInHand = participants.filter((seat) => seat.status === "playing" || seat.status === "all_in");
  const authorityRaise = source.legalActions.find((item) => item.action === "raise" || item.action === "bet");
  const legal = source.legalActions.map((item) => item.action === "bet" ? "raise" : item.action)
    .filter((action): action is VirtualAction => ACTIONS.has(action as VirtualAction));
  return {
    botPlayerId: source.botPlayerId,
    botHoleCards: bot.holeCards.slice(),
    communityCards: table.communityCards.slice(),
    street: table.phase as VirtualStreet,
    pot: table.totalPot(),
    currentBet: table.currentBet,
    callAmount: Math.max(0, table.currentBet - bot.currentBet),
    minRaiseTo: authorityRaise?.min_amount ?? null,
    maxRaiseTo: authorityRaise?.max_amount ?? null,
    botStack: bot.chips,
    botCommittedThisStreet: bot.currentBet,
    bigBlind: table.bigBlind,
    smallBlind: table.smallBlind,
    seatCount: source.seatCount,
    activePlayerCount: participants.length,
    opponentsStillInHand: stillInHand.filter((seat) => seat.playerId !== source.botPlayerId).length,
    position: virtualPosition(bot, participants, table),
    isInPosition: isLastToAct(bot, stillInHand, table),
    legalActions: [...new Set(legal)],
    publicActionHistory: publicHandHistory(table),
    handIndex: source.handIndex,
    decisionIndex: source.decisionIndex,
    sessionSeed: source.sessionSeed,
  };
}

function handParticipants(table: TableState): Seat[] {
  return table.seats.filter((seat) => seat.playerId !== ""
    && ["playing", "all_in", "folded"].includes(seat.status))
    .sort((left, right) => left.seatIndex - right.seatIndex);
}

function orderedAfter(seats: Seat[], anchor: number): Seat[] {
  return [...seats].sort((left, right) => {
    const leftDistance = (left.seatIndex - anchor + 100) % 100;
    const rightDistance = (right.seatIndex - anchor + 100) % 100;
    return leftDistance - rightDistance;
  });
}

function virtualPosition(bot: Seat, participants: Seat[], table: TableState): VirtualPosition {
  if (bot.seatIndex === table.dealerSeat) return "button";
  if (bot.seatIndex === table.smallBlindSeat) return "small_blind";
  if (bot.seatIndex === table.bigBlindSeat) return "big_blind";
  const nonBlind = orderedAfter(participants, table.bigBlindSeat)
    .filter((seat) => ![table.dealerSeat, table.smallBlindSeat, table.bigBlindSeat].includes(seat.seatIndex));
  const index = nonBlind.findIndex((seat) => seat.seatIndex === bot.seatIndex);
  if (index === nonBlind.length - 1) return "cutoff";
  if (index > 0 || nonBlind.length <= 2) return "middle";
  return "early";
}

function isLastToAct(bot: Seat, stillInHand: Seat[], table: TableState): boolean {
  if (stillInHand.length <= 1) return true;
  const anchor = table.phase === "preflop" ? table.bigBlindSeat : table.dealerSeat;
  return orderedAfter(stillInHand, anchor).at(-1)?.seatIndex === bot.seatIndex;
}

function publicHandHistory(table: TableState): PublicPokerAction[] {
  return table.handActions.flatMap((entry) => {
    if (entry.hand_id !== table.handId || entry.type !== "player_action" || !entry.action) return [];
    const normalized = entry.action === "bet" ? "raise" : entry.action;
    if (!ACTIONS.has(normalized as VirtualAction) || !STREETS.has(entry.phase as VirtualStreet)) return [];
    const seat = table.getSeat(entry.seat_index ?? entry.seat_id ?? -1);
    return [{
      playerId: seat?.playerId ?? "",
      street: entry.phase as VirtualStreet,
      action: normalized as VirtualAction,
      amount: Math.max(0, Number(entry.amount ?? 0)),
    }];
  });
}
