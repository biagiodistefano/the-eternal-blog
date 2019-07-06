# The Eternal Blog
An eternal blog, self-governed by the authors, censorship-proof


## About
The goal of this project is to create a public blog that dwells in the
Ethereum blockchain for its logic and on IPFS for its contents.

Decentralizing everything, the Authors will have the power and the burden
to govern the Eternal Blog.

Being censorship-proof, due to the technologies adopted, some form of
limitation to the ever-posting power of the Authors has to be set, the risk
being the unstoppable publishing of illegal content such as child pornography.

## Proposed architecture

The proposed architectures finds its roots in a Karma-based system similar to Reddit's,
but with some key differences.


#### Invitation-only
The blog will be invitation-only.

#### The King
The King (at the beginning will be the one that deploys the contract) will
have the power to **invite Authors**.

#### The Authors
Each Author will have each **10 invitations**; but when they invite another Author,
he/she will have **9 invitations**. The first Author will now have **0 invitations**.
This mechanism is in place because everyone can control as many ethereum addresses as
they want. If no limits are applied, e.g. not zeroing the invitations after one is cast,
anyone could control up to _10!_ Author-addresses, thus compromising the governance.

#### The Posts
Each Post will have an *Author*, an *IPFS hash*, a *Score*, and a *Times Flagged* field.
Each Author will be able to write **21 posts**. Each post can be `upvoted`, `downvoted`, `flagged`.
Upvoting post increases or decreases its `Score` the Author's `Karma`. **If a Post stays at `-10 score`
for more than `24 hours`, or if it gets flagged `10 times`, it gets deleted**.

#### Upvotes
In order to prevent abuse, **Authors from the same chain of invitation, cannot upvote
eachothers' posts**, but they can downvote them (to enforce moderation).

#### Extra Post
If an Author runs out of posts, he/she will be able to post at the **cost of 10 Karma**.

#### Buying Karma
An Author can buy Karma for Ether that goes into the contract's balance.
**The purchased Karma can be only spent for extra posts**.

#### Withdrawing Ether
Each Author can withdraw Ether proportionally to his/her Karma (net of purchased Karma). To prevent **double-withdrawing**, the Karma gained through upvotes will be mirrored to the `shares` field of each Author. **When an author withdraws, he/she spends his/her shares**.

#### Extra Invitations
When an Author gets to `100 Karma`, he/she has the right
to start a fresh chain of invitations with a **new Author with 10 invites**.

#### Knights
To enforce moderation, the King can make Authors Knigths. A Knight can
cast `-10 downvotes` in one shot.

#### King's moderation
To enforce moderation, the King can cast `-100 downvotes` in one shot. But can do so only `once every 24 hours`.

#### Authors ban
If an Author stays at **-20 Karma for 24 hours**, he/she gets banned.

#### Dethroning
The King can be dethroned in favor of another, if so decides **51% of
the total Karma**. Purchased Karma does not count.

#### De-knighting
Knights can be stripped of their roles if so is decided decided by
**1000 Karma coming from different invitation chains**. Purchased Karma does not count.

#### Karma price
The price of the Karma is set to be `1 ether for 100 Karma`. The price can be set by the Authors. **The Authors can propose a new price for 100 Karma once a week**. The price is set to be the average of all the proposals.
