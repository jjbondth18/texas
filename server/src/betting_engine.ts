import type { PlayerActionType, PrivateSnapshot } from "./protocol.js";
import { settleHand } from "./showdown_engine.js";
import type { Seat, TableState } from "./table_state.js";

export function legalActions(table: TableState, playerId: string): PrivateSnapshot["legal_actions"] {
  const seat = table.getSeatByPlayer(playerId);
  if (!seat || table.currentTurnSeat !== seat.seatIndex || seat.status !== "playing") return [];
  const callAmount = Math.max(0, table.currentBet - seat.currentBet);
  const maxTotal = seat.currentBet + seat.chips;
  const actions: PrivateSnapshot["legal_actions"] = [{ action: "fold" }];
  if (callAmount === 0) actions.push({ action: "check", amount: 0 });
  else actions.push({ action: "call", amount: Math.min(callAmount, seat.chips) });
  if (table.currentBet === 0 && maxTotal > 0) {
    actions.push({ action: "bet", min_amount: Math.min(table.bigBlind, maxTotal), max_amount: maxTotal });
  } else if (maxTotal > table.currentBet) {
    actions.push({ action: "raise", min_amount: Math.min(table.minRaiseTo, maxTotal), max_amount: maxTotal });
  }
  actions.push({ action: "all_in", amount: seat.chips });
  return actions;
}

export function applyPlayerAction(table: TableState, playerId: string, action: PlayerActionType, amount = 0): void {
  const seat = table.getSeatByPlayer(playerId);
  if (!seat) throw new Error("player is not seated");
  if (table.currentTurnSeat !== seat.seatIndex) throw new Error("not this player's turn");
  applySeatAction(table, seat, action, amount);
  afterAction(table, seat.seatIndex);
}

export function processAutomaticTurns(table: TableState): void {
  let guard = 0;
  while (guard < 24 && table.currentTurnSeat >= 0 && ["preflop", "flop", "turn", "river"].includes(table.phase)) {
    guard += 1;
    if (!processSingleAutomaticTurn(table, false)) return;
  }
}

export function processSingleAutomaticTurn(table: TableState, includeWarmupAi = false): boolean {
  if (table.currentTurnSeat < 0 || !["preflop", "flop", "turn", "river"].includes(table.phase)) return false;
  const seat = table.getSeat(table.currentTurnSeat);
  if (!seat || seat.status !== "playing") return false;
  const canCheck = seat.currentBet >= table.currentBet;
  if (!seat.disconnected && !(includeWarmupAi && seat.warmupAi)) return false;
  const action = seat.disconnected ? (canCheck ? "check" : "fold") : (canCheck ? "check" : "call");
  applySeatAction(table, seat, action, 0);
  table.addLog(`${seat.name} auto-${action === "check" ? "checks" : action === "call" ? "calls" : "folds"}${seat.disconnected ? " after disconnect" : ""}.`);
  afterAction(table, seat.seatIndex);
  return true;
}

function applySeatAction(table: TableState, seat: Seat, action: PlayerActionType, amount: number): void {
  const callAmount = Math.max(0, table.currentBet - seat.currentBet);
  switch (action) {
    case "fold":
      seat.status = "folded";
      seat.lastAction = "fold";
      seat.lastActionAmount = 0;
      seat.acted = true;
      table.addAction({
        type: "player_action",
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_name: seat.name,
        action: "fold",
        amount: 0,
        message: `${seat.name} folds.`,
      });
      break;
    case "check":
      if (callAmount > 0) throw new Error("cannot check while facing a bet");
      seat.lastAction = "check";
      seat.lastActionAmount = 0;
      seat.acted = true;
      table.addAction({
        type: "player_action",
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_name: seat.name,
        action: "check",
        amount: 0,
        message: `${seat.name} checks.`,
      });
      break;
    case "call": {
      const paid = table.commit(seat, callAmount);
      seat.lastAction = "call";
      seat.lastActionAmount = paid;
      seat.acted = true;
      table.addAction({
        type: "player_action",
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_name: seat.name,
        action: "call",
        amount: paid,
        message: `${seat.name} calls ${paid}.`,
      });
      break;
    }
    case "bet":
    case "raise": {
      const targetTotal = Math.floor(amount);
      if (targetTotal <= table.currentBet) throw new Error(`${action} must exceed current bet`);
      if (targetTotal < table.minRaiseTo && targetTotal < seat.currentBet + seat.chips) throw new Error(`${action} below minimum raise`);
      const paid = table.commit(seat, targetTotal - seat.currentBet);
      table.currentBet = seat.currentBet;
      table.minRaiseTo = table.currentBet + table.bigBlind;
      for (const active of table.actionableSeats()) active.acted = active.seatIndex === seat.seatIndex;
      seat.lastAction = action;
      seat.lastActionAmount = seat.currentBet;
      table.addAction({
        type: "player_action",
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_name: seat.name,
        action,
        amount: seat.currentBet,
        message: `${seat.name} ${action}s to ${seat.currentBet}.`,
      });
      break;
    }
    case "all_in": {
      const before = table.currentBet;
      const paid = table.commit(seat, seat.chips);
      if (seat.currentBet > before) {
        table.currentBet = seat.currentBet;
        table.minRaiseTo = table.currentBet + table.bigBlind;
        for (const active of table.actionableSeats()) active.acted = active.seatIndex === seat.seatIndex;
      } else {
        seat.acted = true;
      }
      seat.lastAction = "all_in";
      seat.lastActionAmount = paid;
      table.addAction({
        type: "player_action",
        seat_id: seat.seatIndex,
        seat_index: seat.seatIndex,
        player_name: seat.name,
        action: "all_in",
        amount: paid,
        message: `${seat.name} is all-in for ${paid}.`,
      });
      break;
    }
  }
}

function afterAction(table: TableState, fromSeat: number): void {
  const live = table.liveSeats();
  if (live.length <= 1) {
    settleHand(table);
    return;
  }
  if (table.actionableSeats().length === 0) {
    table.runoutBoard();
    table.phase = "showdown";
    settleHand(table);
    return;
  }
  if (isBettingRoundComplete(table)) {
    table.advancePhase();
    if (table.phase === "showdown") settleHand(table);
  } else {
    table.currentTurnSeat = table.nextActionableSeat(fromSeat);
  }
  processAutomaticTurns(table);
}

function isBettingRoundComplete(table: TableState): boolean {
  for (const seat of table.actionableSeats()) {
    if (!seat.acted) return false;
    if (seat.currentBet < table.currentBet) return false;
  }
  return true;
}
