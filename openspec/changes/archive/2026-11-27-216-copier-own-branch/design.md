# Design

## Decisions
- **Negate the manager on the group rule.** `matchManagers: ["!copier"]` keeps every other pin of infra in one pull request and leaves only the copier update out.

## Rejected alternatives
- **A narrower package pattern.** The copier source and the Argo CD source both read `https://github.com/dan-petty/infra.git`, so a pattern cannot tell them apart; the manager can.
- **`postUpgradeTasks` that commit before `copier update`.** It needs a global allow list of commands in the Renovate runner and changes the copier manager's own flow.
