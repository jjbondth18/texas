# Complete Hand Lifecycle V1

This backend pass adds a deterministic single-hand Texas Hold'em lifecycle for local/mock play.

## Implemented

- deterministic `start_new_hand(table_state, seed)`
- 52-card deck shuffle and deal
- dealer, small blind, and big blind assignment
- blind posting
- legal action generation
- `fold`, `check`, `call`, `bet`, `raise`, `all_in`
- turn advancement
- street progression: `preflop`, `flop`, `turn`, `river`, `showdown`, `finished`
- early fold victory
- basic showdown settlement using `HandEvaluator`
- public/private snapshot builders
- structured event log
- replay event cursor reconstruction proof
- side-pot data model builder from committed chip levels

## Main Entry Points

```text
scripts/core/hand_lifecycle.gd
HandLifecycle.start_new_hand(...)
HandLifecycle.get_legal_actions(...)
HandLifecycle.apply_action(...)
HandLifecycle.build_public_snapshot(...)
HandLifecycle.build_private_snapshot(...)
```

```text
scripts/services/hand_replay_service.gd
HandReplayService.get_events(...)
HandReplayService.reconstruct_to_event(...)
```

## Side Pot Limitations

The side-pot builder creates deterministic pot levels and eligible seat lists from committed chips. Full independent side-pot settlement for every all-in scenario is still marked as future production work; current showdown award uses the main pot path tested in this slice.

## Evaluator Limitations

`HandEvaluator` now supports common seven-card comparison well enough for smoke-tested hand categories and ties. It is not yet a certified production evaluator and should receive exhaustive fixture coverage before real-money or ranked competitive use.

## Networking Boundary

Public snapshots hide all hole cards unless showdown reveal is active. Private snapshots reveal only the requesting player's own cards.
