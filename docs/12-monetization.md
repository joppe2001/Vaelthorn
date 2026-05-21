# 12 — Monetization

Vaelthorn is **F2P with fair whales**. Free players are first-class citizens.
Paying players spend on time-savings and cosmetics, never on locked content.

This doc defines the line we don't cross and the systems that make spend feel
*good* rather than coerced.

---

## Philosophy

**We are not a casino. We are a game that accepts money.**

- **F2P:** can collect every hero (slowly), reach every PvE encounter, place
  competitively in arena through smart team building.
- **Light spender** ($10–30/mo): comfortable progression, faster acquisition,
  monthly pass value.
- **Whale** ($100+/mo): maximum convenience, faster R5 weapons, VIP perks,
  exclusive cosmetics.

The win condition: a player who plays 2 hours/day for a year should be able
to **compete** with a player who spent $1000 on day one. They won't win every
match, but they won't be locked out of any.

---

## What we will NOT do

The line stays clear. Re-read this whenever a "could we just..." monetization
idea comes up.

- **No hero or weapon gated behind real money only.** Every Mythic is craftable
  with soul stones eventually.
- **No purchase-only rarity tier.** The ladder is the same for everyone.
- **No pay-to-skip core PvE loop.** Stamina is generous; F2P clears all daily
  content.
- **No P2W advantage in PvP beyond what time-spend players also reach.** Whales
  get there faster, not higher.
- **No FOMO timer pressure exceeding 48 hours** on any deal. No "this offer
  expires in 5 minutes."
- **No nested gacha** ("loot box of loot boxes").
- **No real-money trading or player marketplace.** Account-bound everything.
- **No purchase requirements to participate** in PvP, guilds, or co-op.
- **No selling player advantage in seasonal events.** Cosmetic event rewards
  only.
- **No monetization beyond:** gems, cosmetics, VIP perks, monthly/season pass.

If a design idea violates one of these, we cut it. Sustainable F2P games earn
forever. Predatory F2P games burn their playerbase and die in 18 months.

---

## Currency model

(Cross-reference [04 — Progression](04-progression.md). This is the monetization
lens.)

| Currency | Primary source | Real-money? |
|---|---|---|
| **Gold** | Battles, dungeons | Never |
| **Gems** | Purchase + daily / weekly / event play | Yes (primary IAP currency) |
| **Soul Stones** (per hero) | Dupe conversion + soul shop | Indirectly (gems → shop) |
| **Weapon Shards** (per weapon) | Dupe conversion | Indirectly |
| **Stamina** | Time regen + gem refill | Yes (gem cost) |
| **Phoenix Feathers** | Guild raids only | **No real money path** |
| **Celestial Essence** | Co-op raids only | **No real money path** |
| **Promotion Stones** | Promotion dungeons + arena shop | Indirectly |

**Phoenix Feathers and Celestial Essence are intentionally non-purchasable.**
The endgame Mythic ladder is gated behind multiplayer participation, not
spend. This protects the social layer and prevents whales from skipping the
guild fabric.

---

## Gem packs

Pricing tiers tuned to gacha industry norms. **First-time bonus on each pack
applies once per account** — the classic "double your first purchase" hook,
applied per-tier for variety.

| Pack | Gems | First-time bonus | Price (USD) | Pulls (~300/pull) |
|---|---|---|---|---|
| **Starter** | 500 | +500 | $0.99 | ~3 |
| **Small** | 1,200 | +600 | $4.99 | ~6 |
| **Medium** | 2,800 | +1,400 | $9.99 | ~14 |
| **Large** | 6,000 | +3,000 | $19.99 | ~30 |
| **Huge** | 16,000 | +8,000 | $49.99 | ~80 |
| **Whale** | 35,000 | +17,500 | $99.99 | ~175 |

Single hero pull: ~300 gems. 10x pull: 2,700 gems (10% discount). Pity at 100
pulls. So $9.99/mo Monthly Pass keeps a steady drip; $19.99 Large pack gets a
guaranteed Legendary+ per pack.

---

## VIP system

Tracks **cumulative lifetime spend** server-side. Never resets. Quality-of-life
perks at each tier. No hero or weapon is VIP-locked.

| VIP | Cumulative spend | Cumulative perks |
|---|---|---|
| 0 | $0 | Base game |
| 1 | $5 | +1 daily free summon, +1 daily quest slot |
| 2 | $15 | +stamina cap +20 |
| 3 | $25 | +5% gem bonus on future purchases |
| 4 | $50 | +arena entries ×1.5 daily |
| 5 | $100 | +50 gems / day (login claim) |
| 6 | $200 | +exclusive VIP cosmetic frame |
| 7 | $350 | +1 additional daily summon |
| 8 | $500 | +stamina regen ×1.5 |
| 10 | $1,000 | +rotating VIP-exclusive skin (cosmetic) |
| 12 | $2,500 | +exclusive title, VIP support priority |
| 15 | $10,000 | +permanent anniversary skin, "Founder" title |

Design rule: each VIP tier perk is **measured in time saved**, not power
granted. A VIP 8 player levels heroes 50% faster (stamina regen). They don't
have stronger heroes.

---

## Monthly Pass

$9.99 / 30 days.

- **300 gems** immediately on purchase.
- **100 gems / day** for 30 days = 3,000 gems on full claim.
- **1 guaranteed Rare hero** (random from the standard pool).
- **Daily login claims auto** (no manual claim if you miss a day).

Total ~3,300 gems for $10 = ~11 pulls. Consistent, predictable value for a
committed F2P-leaning player. The "if I'm playing this much, the pass pays
for itself" tier.

---

## Season Pass / Battle Pass

$9.99 / 4-week season.

- **Free track:** 50 tiers, modest rewards (small gems, gold, dust).
- **Premium track:** same 50 tiers, generous rewards (~3,000 gems total over
  the season + 1 season-exclusive cosmetic skin + 200 soul stones for a
  rotating featured hero).
- **Tier progress** earned via daily quests, weekly quests, dungeon clears,
  arena wins.

If a player misses tiers due to time, allow paid catch-up (gems per tier,
capped at 10 tiers to prevent paying through the whole pass).

---

## Limited-time offers

Recurring, predictable, transparent.

| Offer | Cadence | Mechanic |
|---|---|---|
| **First Purchase Bonus** | One-time per account | Doubles gems on first purchase of any pack |
| **Weekend Deal** | Fri–Sun | +30% bonus on Medium+ packs |
| **Whale Chest** | Rotating monthly | $99.99 → 35k gems + 5 Featured Hero soul stones + 1 Mythic Dust |
| **Anniversary Bundle** | Annual | $19.99 → 6k gems + 1 anniversary cosmetic + 10 Phoenix Feathers |
| **New Hero Launch Pack** | On each Featured banner debut | $9.99 → 2,800 gems + 50 soul stones for the new hero |

**Hard rule:** no offer has a sub-48-hour timer. No "this expires in 5
minutes" pressure. We push back on the dark patterns the genre normalized.

---

## Platforms & payment

### Phase 8 — itch.io single-player launch

**No IAP.** The game ships as either:

- **Free** with all gacha gems-earnable (recommended for community building).
- **Paid premium** at $9.99 with a generous starter gem grant (one-time
  experience, no gacha pressure).

We pick one based on Phase 7 playtesting.

### Phase 9+ — online launch

Web store via **Stripe** (2.9% + $0.30 per transaction — much better than App
Store's 30%):

1. Player taps "Get Gems" in-game.
2. Opens browser to `store.vaelthorn.app` (or similar).
3. Player logs into their game account on the store.
4. Picks a pack, pays via Stripe.
5. Stripe webhook → server validates → server credits gems to account.
6. Player returns to game → gems are there.

### Mobile (future)

Required: App Store IAP + Google Play Billing. Platform takes 30% (15% if
revenue under $1M/yr). The web store is for desktop; mobile gets platform IAP.

---

## Server requirements (Phase 9+)

See [10 — Server](10-server.md) for full architecture. Monetization-specific:

```sql
CREATE TABLE iap_purchases (
  purchase_id        UUID PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES users(id),
  platform           TEXT NOT NULL,    -- 'stripe' | 'apple' | 'google'
  platform_tx_id     TEXT UNIQUE NOT NULL,
  pack_id            TEXT NOT NULL,    -- 'gems_medium', 'monthly_pass', etc.
  amount_usd_cents   INT NOT NULL,
  gems_granted       INT NOT NULL,
  bonus_gems         INT NOT NULL DEFAULT 0,
  status             TEXT NOT NULL,    -- 'pending' | 'completed' | 'refunded' | 'failed'
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at       TIMESTAMPTZ NULL,
  refunded_at        TIMESTAMPTZ NULL
);
CREATE INDEX iap_purchases_user ON iap_purchases(user_id, created_at DESC);

CREATE TABLE vip_state (
  user_id            UUID PRIMARY KEY REFERENCES users(id),
  vip_tier           INT NOT NULL DEFAULT 0,
  lifetime_usd_cents BIGINT NOT NULL DEFAULT 0,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### Receipt validation

Every purchase **must** be server-validated against the platform.

- **Stripe:** webhook with signed event payload. Verify signature server-side.
- **Apple:** App Store Server API receipt validation.
- **Google:** Google Play Developer API purchase token verification.

Client never grants gems. Client tells server "purchase happened" → server
verifies with platform → server grants gems.

### Refund handling

On chargeback / refund:

1. Platform webhook fires (Stripe, Apple, Google all support this).
2. Server marks purchase `refunded`.
3. Server revokes the granted gems. If gems are spent and balance is
   negative, account enters "balance owed" state — limited features until
   resolved or 30 days pass (then account locked pending support).

This protects against the "buy gems, pull, chargeback, keep heroes" exploit
that destroys gacha game revenue.

### Anti-fraud

- Rate-limit purchase attempts (5/hour per account).
- Multi-account detection: same payment method on N accounts → flag.
- Velocity checks: $500+ in 24h → manual review.

---

## Compliance (legal, non-negotiable)

| Requirement | Why | Where addressed |
|---|---|---|
| **Public loot box rates** | Legal: Belgium, Netherlands, China, others; recommended elsewhere | In-game "Rates" button on every banner; legal page on store |
| **Privacy policy** | GDPR, CCPA, COPPA | Linked from settings, store, registration |
| **Terms of Service** | Required by App Store, Play Store, Stripe | Same |
| **Age gate** | COPPA (under 13); we set 13+ minimum | Registration flow |
| **GDPR right to deletion** | EU law | Account deletion flow that purges server data |
| **Auto-renewal disclosure** | App Store, Play Store, FTC | On Monthly Pass / Season Pass purchase screens |
| **Refund policy** | Standard consumer protection | Linked from store |
| **Tax handling** | Per-jurisdiction | Stripe Tax / platform IAP handle automatically |
| **Wallet ledger / audit log** | Required for some regions | `iap_purchases` table persisted indefinitely |

Don't half-do compliance. One bad PR cycle around a loot box scandal kills a
small game. Get this right at Phase 9 launch.

---

## Telemetry (cross-reference [11](11-engineering.md))

Key monetization metrics:

- **Conversion** (% of free players → first paid purchase)
- **ARPU** (avg revenue per user, including free)
- **ARPPU** (avg revenue per paying user)
- **Whale concentration** (top 1% spenders share of total revenue — industry
  norm: 50%; we aim closer to 30–40% by widening the middle)
- **Churn correlation** by spend tier
- **Pack popularity** distribution
- **Monthly Pass attach rate** (% of active players holding active pass)

Track these from Phase 9 day one. Make data-driven balance decisions. Don't
guess.

---

## Rollout

| Phase | Monetization milestone |
|---|---|
| 0–7 | None. Pure build phase. |
| 8 | itch.io launch — free OR $9.99 paid premium, **no IAP** |
| 9 | Accounts launch; web store with Stripe; gem packs go live |
| 10 | Arena launch; arena cosmetic frames (gem cost only); no new monetization |
| 11 | Guilds launch; cosmetic guild flags; no new monetization |
| 12 | **Monthly Pass introduced.** Guild raid launch. |
| 13 | Co-op raids launch; **Season Pass introduced** |
| 14+ | Live-ops cadence: rotating cosmetics, anniversary events, themed bundles |

---

## A note on what F2P actually means here

Free-to-play in this design is not a marketing label. It's a *contract* with
the player:

- You can play forever without spending.
- You can collect every hero. Slowly.
- You can compete in PvP through smart play.
- You can clear every PvE encounter.
- You will not be reminded you should have spent more.

If a feature breaks this contract, the feature loses. Always.
