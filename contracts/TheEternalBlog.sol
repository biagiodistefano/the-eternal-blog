pragma solidity ^0.5.10;

contract TheEternalBlog {
    
    address payable public king;
    int256 totalKarma;
    uint256 totalShares;
    
    uint public karmaPrice = 1 finney;
    uint karmaPriceVotes = 1;
    uint karmaPriceSum = 1 finney;
    mapping(address => uint256) lastTimeVotedKarmaPrice;
    
    uint public flagsToPostDeletion = 10;
    uint flagsToPostDeletionVotes = 1;
    uint flagsToPostDeletionSum = 10;
    mapping(address => uint256) lastTimeVotedFlagsToPostDeletion;
    
    uint public flagsToAuthorDeletion = 50;
    uint flagsToAuthorDeletionVotes = 1;
    uint flagsToAuthorDeletionSum = 50;
    mapping(address => uint256) lastTimeVotedFlagsToAuthorDeletion;
    
    uint public kingModPower = 100;
    uint kingModPowerVotes = 1;
    uint kingModPowerSum = 100;
    mapping(address => uint256) lastTimeVotedKingModPower;
    
    uint public knightModPower = 50;
    uint knightModPowerVotes = 1;
    uint knightModPowerSum = 50;
    mapping(address => uint256) lastTimeVotedKnightModPower;
    
    uint public bishopModPower = 5;
    uint bishopModPowerVotes = 1;
    uint bishopModPowerSum = 5;
    mapping(address => uint256) lastTimeVotedBishopModPower;
    
    uint public karmaToBishop = 100;
    uint karmaToBishopVotes = 1;
    uint karmaToBishopSum = 100;
    mapping(address => uint256) lastTimeVotedKarmaToBishop;
    
    struct Multihash {
        bytes32 digest;
        uint8 hashFunction;
        uint8 size;
      }
    
    struct Author {
        address payable _address;
        address invitationRoot;
        address parent;
        address child;
        uint256[] postIndex;
        uint256 totalPosts;
        uint256 flagsReceived;
        int8 postsLeft;
        mapping (uint256 => bool) castedVotes;
        uint8 invitationsLeft;
        int256 karma;
        int256 shares;
        int256 purchasedKarma;
        uint id;
        bool isAuthor;
        uint256 index;
    }
    
    struct Post {
        address payable author;
        bytes32 title;
        uint256 ipfsHashId;
        int256 score;
        uint256 flagsReceived;
        uint256 publishedOn;
        uint256 id;
        uint256 index;
        uint256 privateIndex;
        bool exists;
    }
    
    mapping(address => Author) public authors;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => address) public postIdToAuthor;
    mapping(address => bool) public knights;
    mapping(address => bool) public bishops;
    
    Multihash[] private ipfsHashes;
    uint256[] public postIndex;
    address[] public authorsIndex;
    uint private nextPostId;
    uint public totalPosts;
    
    event FreshAuthor(address author, address invitedBy);
    event NewKnight(address author);
    event RemovedKnight(address author);
    event NewAuthor(address author, address invitedBy);
    event NewPost(uint256 postId, address author);
    event PostDeleted(uint256 postId);
    event PostDownvoted(uint256 postId, address downvotedBy);
    event KarmaPurchase(int256 quantity, uint256 price, address purchasedBy);
    
    constructor() public {
        king = msg.sender;
    }
    
    modifier onlyKing {
        require(msg.sender == king, "Only the king can perform this action.");
        _;
    }
    
    modifier onlyAuthors {
        require(authors[msg.sender].isAuthor, "Only Authors can perform this action.");
        _;
    }
    
    modifier canInvite {
        require(authors[msg.sender].isAuthor, "You must be an Author to invite other authors.");
        require(authors[msg.sender].invitationsLeft > 0, "You don't have any invitations left.");
        require(authors[msg.sender].karma - authors[msg.sender].purchasedKarma >= 0, "You don't have enough Karma to invite.");
        _;
    }
    
    modifier canVotePost(uint256 _postId) {
        require(authors[msg.sender].isAuthor, "Only Authors can vote.");
        require(posts[_postId].exists, "The post does not exist.");
        require(authors[msg.sender].karma - authors[msg.sender].purchasedKarma > -10, "You don't have enough Karma to vote.");
        require(!authors[msg.sender].castedVotes[_postId], "You have already voted this post.");
        _;
    }
    
    modifier canWithdraw(int256 _shares) {
        require(authors[msg.sender].shares > 0, "You don't have any shares.");
        require(_shares > 0, "You must enter a value greater than 0.");
        require(_shares <= authors[msg.sender].shares, "You can't withdraw that much.");
        _;
    }
    
    function newAuthor(address payable _address) public onlyKing {
        Author memory author;
        author._address = _address;
        author.invitationRoot = _address;
        author.parent = msg.sender;
        author.isAuthor = true;
        author.invitationsLeft = 10;
        author.postsLeft = 21;
        uint256 id = authorsIndex.push(_address)-1;
        author.id = id;
        authors[_address] = author;
        emit FreshAuthor(_address, msg.sender);
    }
    
    function makeKnight(address _address) public onlyKing {
        require(authors[_address].isAuthor, "Only Authors can become knights.");
        require(authors[_address].karma - authors[_address].purchasedKarma > 0, "Authors with negative Karma can't be knights.");
        knights[_address] = true;
        emit NewKnight(_address);
    }
    
    function removeKnight(address _address) public onlyKing {
        require(knights[_address], "The Author is not a Knight.");
        knights[_address] = false;
        emit RemovedKnight(_address);
    }
    
    function makeBishop(address _address) public onlyAuthors {
        require(authors[_address].karma > 0);
        require(uint256(authors[_address].karma) >= karmaToBishop);
        bishops[_address] = true;
    }
    
    function removeBishop(address _address) public onlyAuthors {
        require(uint256(authors[_address].karma) < karmaToBishop);
        bishops[_address] = false;
    }
    
    function inviteAuthor(address payable _address) public canInvite {
        require(_address != msg.sender, "You cannot invite yourself.");
        Author memory author;
        author._address = _address;
        author.invitationRoot = authors[msg.sender].invitationRoot;
        author.parent = msg.sender;
        authors[msg.sender].child = _address;
        author.invitationsLeft = authors[msg.sender].invitationsLeft-1;
        authors[msg.sender].invitationsLeft = 0;
        author.postsLeft = 21;
        author.isAuthor = true;
        uint256 id = authorsIndex.push(_address)-1;
        author.id = id;
        authors[_address] = author;
        emit NewAuthor(_address, msg.sender);
    }
    
    function deleteAuthor(address _author) internal {
        uint rowToDelete = authors[_author].index;
        address idToMove = authorsIndex[authorsIndex.length-1];
        authorsIndex[rowToDelete] = idToMove;
        authors[idToMove].index = rowToDelete;
        authorsIndex.length--;
        delete authors[_author];
    }
    
    function newPost(bytes32 _postTitle, bytes32 _digest, uint8 _hashFunction, uint8 _size) public onlyAuthors {
        require(authors[msg.sender].postsLeft > 0 || authors[msg.sender].karma >= 10, "You don't have any posts left nor enough karma.");
        Multihash memory multihash = Multihash(_digest, _hashFunction, _size);
        uint256 hashId = ipfsHashes.push(multihash)-1;
        Post memory post;
        post.author = msg.sender;
        post.title = _postTitle;
        post.ipfsHashId = hashId;
        post.publishedOn = now;
        post.id = nextPostId;
        post.exists = true;
        nextPostId++;
        uint index = postIndex.push(post.id)-1;
        uint privateIndex = authors[msg.sender].postIndex.push(post.id)-1;
        post.privateIndex = privateIndex;
        posts[post.id] = post;
        posts[post.id].index = index;
        postIdToAuthor[post.id] = msg.sender;
        if (authors[msg.sender].postsLeft == 0) {
            authors[msg.sender].karma -= 10;
        }
        if (msg.sender != king && authors[msg.sender].postsLeft > 0) {
            authors[msg.sender].postsLeft--;
        }
        totalPosts++;
        authors[msg.sender].totalPosts++;
        emit NewPost(post.id, msg.sender);
    }
    
    function deletePost(uint256 _postId) internal {
        uint rowToDelete = posts[_postId].index;
        uint idToMove = postIndex[postIndex.length-1];
        postIndex[rowToDelete] = idToMove;
        posts[idToMove].index = rowToDelete;
        postIndex.length--;
        
        uint privateRowToDelete = posts[_postId].privateIndex;
        uint privateIdToMove = authors[posts[_postId].author].postIndex[authors[posts[_postId].author].postIndex.length-1];
        authors[posts[_postId].author].postIndex[privateRowToDelete] = privateIdToMove;
        posts[privateIdToMove].privateIndex = privateRowToDelete;
        authors[posts[_postId].author].postIndex.length--;
        
        delete posts[_postId];
        delete postIdToAuthor[_postId];
        totalPosts--;
        authors[posts[_postId].author].totalPosts--;
        emit PostDeleted(_postId);
    }
    
    function upvotePost(uint256 _postId) public canVotePost(_postId) {
        require(authors[msg.sender].invitationRoot != authors[posts[_postId].author].invitationRoot,
        "You cannot upvote Posts from your own invitation chain.");
        posts[_postId].score++;
        authors[posts[_postId].author].karma++;
        authors[posts[_postId].author].shares++;
        totalKarma++;
        if (authors[posts[_postId].author].shares > 0) {
            totalShares++;
        }
        authors[msg.sender].castedVotes[_postId] = true;
    }
    
    function downvotePost(uint256 _postId) public canVotePost(_postId) {
        posts[_postId].score--;
        posts[_postId].flagsReceived++;
        authors[posts[_postId].author].karma--;
        authors[posts[_postId].author].flagsReceived++;
        authors[posts[_postId].author].shares--;
        totalKarma--;
        if (authors[posts[_postId].author].shares >= 0) {
            totalShares--;
        }
        authors[msg.sender].castedVotes[_postId] = true;
        if (posts[_postId].flagsReceived >= flagsToPostDeletion) {
            deletePost(_postId);
        }
        if (authors[posts[_postId].author].flagsReceived >= flagsToAuthorDeletion) {
            deleteAuthor(posts[_postId].author);
        }
    }
    
    function flagPost(uint256 _postId) public canVotePost(_postId) {
        uint256 downvotes = 1;
        if (msg.sender == king) {
            downvotes = kingModPower;
        } else if (knights[msg.sender]) {
            downvotes = knightModPower;
        } else if (bishops[msg.sender]) {
            downvotes = bishopModPower;
        }
        posts[_postId].score -= int256(downvotes);
        posts[_postId].flagsReceived += downvotes;
        authors[posts[_postId].author].karma -= int256(downvotes);
        authors[posts[_postId].author].flagsReceived += downvotes;
        totalKarma -= int256(downvotes);
        if (authors[posts[_postId].author].shares - int256(downvotes) >= 0) {
            totalShares -= downvotes;
        } else {
            totalShares -= uint256(authors[posts[_postId].author].shares);
        }
        authors[posts[_postId].author].shares -= int256(downvotes);
        if (posts[_postId].flagsReceived <= flagsToPostDeletion) {
            deletePost(_postId);
        }
        if (authors[posts[_postId].author].flagsReceived <= flagsToAuthorDeletion) {
            deleteAuthor(posts[_postId].author);
        }
    }
    
    function voteKarmaPrice(uint256 _karmaPrice) public {
        require(authors[msg.sender].isAuthor, "Only Authors can vote on Karma price");
        require(now - lastTimeVotedKarmaPrice[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        karmaPriceVotes++;
        karmaPriceSum += _karmaPrice;
        karmaPrice = karmaPriceSum/karmaPriceVotes;
        lastTimeVotedKarmaPrice[msg.sender] = now;
    }
    
    function voteFlagsToPostDeletion(uint256 _flagsToPostDeletion) public onlyAuthors {
        require(now - lastTimeVotedFlagsToPostDeletion[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        flagsToPostDeletionVotes++;
        flagsToPostDeletionSum += _flagsToPostDeletion;
        flagsToPostDeletion = flagsToPostDeletionSum/flagsToPostDeletionVotes;
        lastTimeVotedFlagsToPostDeletion[msg.sender] = now;
    }
    
    function voteFlagsToAuthorDeletion(uint256 _flagsToAuthorDeletion) public onlyAuthors {
        require(now - lastTimeVotedFlagsToAuthorDeletion[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        flagsToAuthorDeletionVotes++;
        flagsToAuthorDeletionSum += _flagsToAuthorDeletion;
        flagsToAuthorDeletion = flagsToAuthorDeletionSum/flagsToAuthorDeletionVotes;
        lastTimeVotedFlagsToAuthorDeletion[msg.sender] = now;
    }
    
    function voteKingModPower(uint256 _kingModPower) public onlyAuthors {
        require(now - lastTimeVotedKingModPower[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        kingModPowerVotes++;
        kingModPowerSum += _kingModPower;
        kingModPower = kingModPowerSum/kingModPowerVotes;
        lastTimeVotedKingModPower[msg.sender] = now;
    }
    
    function voteKnightModPower(uint256 _knightModPower) public onlyAuthors {
        require(now - lastTimeVotedKnightModPower[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        knightModPowerVotes++;
        knightModPowerSum += _knightModPower;
        knightModPower = knightModPowerSum/knightModPowerVotes;
        lastTimeVotedKnightModPower[msg.sender] = now;
    }
    
    function voteBishopModPower(uint256 _bishopModPower) public onlyAuthors {
        require(now - lastTimeVotedBishopModPower[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        bishopModPowerVotes++;
        bishopModPowerSum += _bishopModPower;
        bishopModPower = bishopModPowerSum/bishopModPowerVotes;
        lastTimeVotedBishopModPower[msg.sender] = now;
    }
    
    function voteKarmaToBishop(uint256 _karmaToBishop) public onlyAuthors {
        require(now - lastTimeVotedKarmaToBishop[msg.sender] > 1 weeks, "You can vote on this matter only once a week.");
        karmaToBishopVotes++;
        karmaToBishopSum += _karmaToBishop;
        karmaToBishop = karmaToBishopSum/karmaToBishopVotes;
        lastTimeVotedKarmaToBishop[msg.sender] = now;
    }
    
    function buyKarma() payable public {
        require(authors[msg.sender].isAuthor, "Only authors can buy Karma.");
        int256 quantity = int256(msg.value/karmaPrice);
        authors[msg.sender].karma += quantity;
        authors[msg.sender].purchasedKarma += quantity;
        emit KarmaPurchase(quantity, msg.value, msg.sender);
    }
    
    function withdrawEther(int256 _sharesToUse) public canWithdraw(_sharesToUse) {
        uint256 amount = uint256(authors[msg.sender].shares) * address(this).balance / totalShares;
        authors[msg.sender].shares -= _sharesToUse;
        totalShares -= uint256(_sharesToUse);
        msg.sender.transfer(amount);
    }
}