pragma solidity ^0.5.10;

contract TheEternalBlog {
    
    address public king;
    int256 totalKarma;
    int256 totalShares;
    
    mapping (uint8 => uint256) public authorVotedValues;
    mapping (uint8 => uint256) authorVoteCount;
    mapping (uint8 => uint256) authorVoteSum;
    mapping (address => mapping(uint8 => uint256)) authorLastTimeVoted;
    
    struct Dethroning {
        uint start;
        int256 totalDTKarma;
        mapping (address => int256) candidates;
        mapping (address => bool) voted;
        address[] candidatesIndex;
        uint candidatesCount;
        bool open;
    }
    
    Dethroning[] public dethroningAttempts;
    uint public currentDethroning;
    
    // This holds IPFS hashes
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
    mapping(address => bool) public bannedAuthors;
    mapping(uint256 => Post) public posts;
    mapping(uint256 => address) public postIdToAuthor;
    mapping(address => bool) public knights;
    mapping(address => bool) public bishops;
    
    Multihash[] private ipfsHashes;
    uint256[] public postIndex;
    address[] public authorsIndex;
    uint private nextPostId;
    uint public totalPosts;
    
    event NewKing(address _king);
    event FreshAuthor(address author, address invitedBy);
    event NewKnight(address author);
    event RemovedKnight(address author);
    event NewAuthor(address author, address invitedBy);
    event AuthorBanned(address author);
    event NewPost(uint256 postId, address author);
    event PostDeleted(uint256 postId);
    event PostDownvoted(uint256 postId, address downvotedBy);
    event KarmaPurchase(int256 quantity, uint256 price, address purchasedBy);
    
    constructor() public {
        king = msg.sender;
    }
    
    modifier onlyKing {
        require(msg.sender == king);
        _;
    }
    
    modifier onlyAuthors {
        require(authors[msg.sender].isAuthor);
        _;
    }
    
    modifier canInvite {
        require(authors[msg.sender].isAuthor);
        require(authors[msg.sender].invitationsLeft > 0);
        require(authors[msg.sender].karma - authors[msg.sender].purchasedKarma >= 0);
        _;
    }
    
    modifier canVotePost(uint256 _postId) {
        require(authors[msg.sender].isAuthor);
        require(posts[_postId].exists);
        require(authors[msg.sender].karma - authors[msg.sender].purchasedKarma > -10);
        require(!authors[msg.sender].castedVotes[_postId]);
        _;
    }
    
    modifier canWithdraw(int256 _shares) {
        require(authors[msg.sender].shares > 0);
        require(_shares > 0);
        require(_shares <= authors[msg.sender].shares);
        _;
    }
    
    function newAuthor(address payable _address) public onlyKing {
        require(!authors[_address].isAuthor && !bannedAuthors[_address]);
        Author memory author;
        author._address = _address;
        author.invitationRoot = _address;
        author.parent = msg.sender;
        author.isAuthor = true;
        author.invitationsLeft = 10;
        author.postsLeft = 21;
        authors[_address] = author;
        emit FreshAuthor(_address, msg.sender);
    }
    
    function makeKnight(address _address) public onlyKing {
        require(authors[_address].isAuthor);
        require(authors[_address].karma - authors[_address].purchasedKarma > 0);
        knights[_address] = true;
        emit NewKnight(_address);
    }
    
    function removeKnight(address _address) public onlyKing {
        require(knights[_address]);
        knights[_address] = false;
        emit RemovedKnight(_address);
    }
    
    function makeBishop(address _address) public onlyAuthors {
        require(authors[_address].karma > 0);
        require(uint256(authors[_address].karma) >= karmaToBishop());
        bishops[_address] = true;
    }
    
    function removeBishop(address _address) public onlyAuthors {
        require(uint256(authors[_address].karma) < karmaToBishop());
        bishops[_address] = false;
    }
    
    function inviteAuthor(address payable _address) public canInvite {
        require(_address != msg.sender && !bannedAuthors[_address]);
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
    
    function banAuthor(address _author) internal {
        uint rowToDelete = authors[_author].index;
        address idToMove = authorsIndex[authorsIndex.length-1];
        authorsIndex[rowToDelete] = idToMove;
        authors[idToMove].index = rowToDelete;
        authorsIndex.length--;
        bannedAuthors[_author] = true;
        if (authors[_author].karma > 0) {
            totalKarma -= authors[_author].karma;
        }
        if (authors[_author].shares > 0) {
            totalShares -= authors[_author].shares;
        }
        delete authors[_author];
        emit AuthorBanned(_author);
    }
    
    function newPost(bytes32 _postTitle, bytes32 _digest, uint8 _hashFunction, uint8 _size) public onlyAuthors {
        require(authors[msg.sender].postsLeft > 0 || authors[msg.sender].karma >= 10);
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
        require(authors[msg.sender].invitationRoot != authors[posts[_postId].author].invitationRoot);
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
    }
    
    function flagPost(uint256 _postId) public canVotePost(_postId) {
        uint256 downvotes = 1;
        if (msg.sender == king) {
            downvotes = kingModPower();
        } else if (knights[msg.sender]) {
            downvotes = knightModPower();
        } else if (bishops[msg.sender]) {
            downvotes = bishopModPower();
        }
        posts[_postId].score -= int256(downvotes);
        posts[_postId].flagsReceived += downvotes;
        authors[posts[_postId].author].karma -= int256(downvotes);
        authors[posts[_postId].author].flagsReceived += downvotes;
        totalKarma -= int256(downvotes);
        if (authors[posts[_postId].author].shares - int256(downvotes) >= 0) {
            totalShares -= int(downvotes);
        } else if (authors[posts[_postId].author].shares > 0) {
            totalShares -= authors[posts[_postId].author].shares;
        }
        authors[posts[_postId].author].shares -= int256(downvotes);
        if (posts[_postId].flagsReceived <= flagsToPostDeletion()) {
            deletePost(_postId);
        }
        if (authors[posts[_postId].author].flagsReceived <= flagsToAuthorBan()) {
            banAuthor(posts[_postId].author);
        }
    }
    
    function vote(uint8 _what, uint256 _value) public {
        require(authors[msg.sender].isAuthor);
        require(_what < 7);
        require(now - authorLastTimeVoted[msg.sender][_what] > 1 weeks);
        authorVoteCount[_what] ++;
        authorVoteSum[_what] += _value;
        authorVotedValues[_what] = authorVoteSum[_what]/authorVoteCount[_what];
        authorLastTimeVoted[msg.sender][_what] = now;
    }
    
    function buyKarma() payable public {
        require(authors[msg.sender].isAuthor);
        int256 quantity = int256(msg.value/karmaPrice());
        authors[msg.sender].karma += quantity;
        authors[msg.sender].purchasedKarma += quantity;
        emit KarmaPurchase(quantity, msg.value, msg.sender);
    }
    
    function withdrawEther(int256 _sharesToUse) public canWithdraw(_sharesToUse) {
        int256 amount = authors[msg.sender].shares * int256(address(this).balance / uint256(totalShares));
        authors[msg.sender].shares -= _sharesToUse;
        totalShares -= _sharesToUse;
        msg.sender.transfer(uint256(amount));
    }
    
    function dethrone(address _addressToVote) public onlyAuthors {
        require(dethroningAttempts[currentDethroning].open);
        require(authors[msg.sender].isAuthor && authors[msg.sender].karma - authors[msg.sender].purchasedKarma > 0);
        require(authors[_addressToVote].isAuthor);
        require(authors[msg.sender].invitationRoot != authors[_addressToVote].invitationRoot);
        require(dethroningAttempts[currentDethroning].start < 1 weeks);
        require(!dethroningAttempts[currentDethroning].voted[msg.sender]);
        if (dethroningAttempts[currentDethroning].candidates[_addressToVote] == 0) {
            dethroningAttempts[currentDethroning].candidatesIndex.push(_addressToVote);
            dethroningAttempts[currentDethroning].candidatesCount++;
        }
        dethroningAttempts[currentDethroning].candidates[_addressToVote] += authors[msg.sender].karma - authors[msg.sender].purchasedKarma;
        if (dethroningAttempts[currentDethroning].candidates[_addressToVote] > dethroningAttempts[currentDethroning].totalDTKarma/2) {
            king = _addressToVote;
            dethroningAttempts[currentDethroning].open = false;
            emit NewKing(_addressToVote);
        }
    }
    
    function newDethroning() public onlyAuthors {
        require(dethroningAttempts.length == 0 || dethroningAttempts[dethroningAttempts.length-1].start > 1 weeks);
        Dethroning memory dethroning;
        dethroning.start = now;
        dethroning.totalDTKarma = totalKarma;
        dethroning.open = true;
        currentDethroning = dethroningAttempts.push(dethroning)-1;
    }
    
    function karmaPrice() public view returns(uint256 value) {
        return authorVotedValues[0];
    }
    
    function flagsToPostDeletion() public view returns(uint256 value) {
        return authorVotedValues[1];
    }
    
    function flagsToAuthorBan() public view returns(uint256 value) {
        return authorVotedValues[2];
    }
    
    function kingModPower() public view returns(uint256 value) {
        return authorVotedValues[3];
    }
    
    function knightModPower() public view returns(uint256 value) {
        return authorVotedValues[4];
    }
    
    function bishopModPower() public view returns(uint256 value) {
        return authorVotedValues[5];
    }
    
    function karmaToBishop() public view returns(uint256 value) {
        return authorVotedValues[6];
    }
    
}