# The Eternal Blog
An eternal blog, self-governed by the Authors, censorship-proof

## About
The goal of this project is to create a public blog that dwells in the
Ethereum blockchain for its logic and on IPFS for its contents.

Decentralizing everything, the Authors will have the power and the burden
to govern the Eternal Blog.

Being censorship-proof due to the technologies adopted, some form of
limitation to the ever-posting power of the Authors has to be set, the risk
being the unstoppable publishing of illegal content such as child pornography.

## Proposed architecture

The proposed architectures finds its roots in a Karma-based system similar to Reddit's,
but with some key differences.

### Governing highlights

The power of governing belongs to the Authors.

Once a week, the Authors can:

- elect a new King;
- determine the price of Karma;
- determine the King's moderation power;
- determine the Knights' moderation power;
- determine the Karma needed to become Bishop.
- determine the Bishops' moderation power;

#### Invitation-only
The blog will be invitation-only. The King has the power to invite any number of
Authors as he pleases. The Author themselves can start an invitation-chain of up
to `10 Authors`.

#### The King
The King (that at the beginning will be the one that deploys the contract) will
have the power to **invite New Authors**.

He/she has moderation powers that are determined by the authors.

#### Dethroning
- The King can be dethroned by the Authors through elections that can happen
once a week.
- Each Authors vote counts as much as his/her karma at the moment of the vote,
and has to be > 0. Purchased Karma is subtracted to Authors' Karma.
- Authors cannot vote candidates from their own invitation list.
- A candidate, in order to become the new King, has to obtain more than half of
the total Karma existing at the moment of the beginning of the new election.

#### The Authors
Each Fresh Author will have **10 invitations** each; but when they invite another Author,
tha latter will have **9 invitations**. The first Author will now have **0 invitations**.

Example:
- The `King` invites `A`. `A` has `10 invites` to use.
- `A` invites `B`. Now `A` has `0 invites`, while `B` has `9 invites`.
- `B` invites `C`. Now `B` has `0 invites`, while `C` has `8 invites`.

This mechanism is in place since everyone can control as many ethereum addresses as
they want. If no limits are applied, e.g. not zeroing the invitations after one is cast,
anyone could control up to _10!_ Author-addresses, thus compromising the governance.

In the previous example, `A`, `B` and `C` belong to the same invitation
chain, thus they cannot upvote eachother's posts, nor can they vote
eachothers for Kingship.

Each Author will be entitled to write **21 posts**. After those are spent, Authors will
be able to post by spending `10 Karma`.

#### Karma
Each Author will start with 0 Karma. Karma is increased or decreased by getting upvotes
or downvotes on the Authors' posts. Karma can also be negative.

Karma can be bought at `karmaPrice()`. The price is determined by the Authors.
The ether spent to buy Karma goes to the balance of the contract and can be withdrawn
by Authors by spending their `shares`.

#### Shares
Similar to Karma for the mechanism, it gives the authors the right to withraw Ether
proportionally to the `totalShares`.

Example:
- Let's say there are `totalShares = 100`;
- The contract's `balance = 10 ether`;
- You have `shares = 10`;
- You can withdraw up to `1 ether`.

It is believed that this mechanism will incetivize Authors to post quality
content.

#### The Posts
Each Post will have an *Author*, an *IPFS hash*, a *Score*, and a *Times Flagged* field.
Each Author will be able to write **21 posts**. Each post can be `upvoted`, `downvoted`, `flagged`.

#### Voting and flagging Posts.
In order to prevent abuse, **Authors from the same chain of invitation, cannot upvote
eachothers' posts**, but they can downvote and flag them (to enforce moderation).

Upvoting or downvoting post increases or decreases its `Score`, the Author's and
total `Karma` and `Shares`.

**If a Post gets flagged `flagsToPostDeletion()` times, it gets deleted**.

Flagging a post counts also as a downvote.

#### Extra Posts
If an Author runs out of posts, he/she will be able to post at the **cost of 10 Karma**.

#### Buying Karma
An Author can buy Karma for Ether at `karmaPrice()` that goes into the contract's balance.
**The purchased Karma can be only spent for extra posts and does not count
in voting mechanisms**.

Karma price is set by the Authors.

#### Withdrawing Ether
Each Author can withdraw Ether proportionally to his/her Karma (net of purchased Karma). To prevent **double-withdrawing**, the Karma gained through upvotes will be mirrored to the `shares` field of each Author. **When an author withdraws, he/she spends his/her shares**.

## Moderation

`King`, `knights` and `bishops` are the one responsible for moderating the content.

- `knights` are made and removed by the `King`.
- `bishops` are made by the Authors when one gets to `karmaToBishop()` Karma.

#### King's moderation
To enforce moderation, the King can cast `kingModPower()` in one shot.

#### Knights' moderation
To enforce moderation, the King can make Authors Knigths. A Knight can
cast `knightModPower()` flags in one shot.

#### Bishops' moderation
To enforce moderation, the King can make Authors Knigths. A Knight can
cast `bishopModPower()` flags in one shot.

#### Authors ban
If an Author stays gets `flagsToAuthorBan()` flags, he/she gets banned.

#### Note on Posts deletion
Naturally, when a post gets "deleted" it simply gets removed from the
posts mapping and index. But being stored on IPFS, which is outside
of the contract's control, it could somehow be retrieved, for instance
calling the contract at a block previous of the post's deletion.
