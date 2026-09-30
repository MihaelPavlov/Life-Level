---
type: "query"
date: "2026-09-29T20:22:00.492150+00:00"
question: "DId we split the telants crystals and the gems"
contributor: "graphify"
outcome: "useful"
source_nodes: ["UserTalentWallet", "TalentService", "IShopWalletPort", "TalentWallet"]
---

# Q: DId we split the telants crystals and the gems

## Answer

Expanded from original query via graph vocab: [talent, talents, crystal, crystals, gem, gems, wallet, currency]. No. Talent Crystals and Shop Gems are currently the same backend balance: UserTalentWallet.Crystals. TalentService maps that value into ShopWalletBalance.Gems, so spending Gems in the shop decreases the same Crystals used for talent draws. The Flutter UI gives the same balance different names.

## Outcome

- Signal: useful

## Source Nodes

- UserTalentWallet
- TalentService
- IShopWalletPort
- TalentWallet