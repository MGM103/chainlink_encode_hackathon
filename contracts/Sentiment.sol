// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//Utils
import "hardhat/console.sol";

//Openzeppelin contract imports
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
//import "@openzeppelin/contracts/access/AccessControl.sol";

//Chainlink contract imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Sentiment is ERC721URIStorage, VRFConsumerBaseV2 {
    //Chainlink VRF variables
    VRFCoordinatorV2Interface internal immutable COORDINATOR;
    uint64 internal immutable subscriptionId;
    bytes32 internal immutable keyHash;
    uint32 internal immutable callbackGasLimit;
    uint16 internal immutable requestConfirmations;
    uint32 internal immutable numWords;

    //Role based access control setup
    //bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    //Use open zeplin counters for iterator object
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //These colors will be used as randomly generated backgrounds
    uint256 constant private WORDLIMIT = 10;
    uint256 constant private NUMCOLOURS = 7;
    string[WORDLIMIT] private words;
    string[NUMCOLOURS] backgroundColours = ["#ba56f6", "#001133", "#f8b500", "#042069", "#c0ebff", "#ff748c", "#ff8da1"];

    mapping(uint256 => address) requestIdToRequester;
    mapping(address => uint256) ownerToNFT;

    event CreateNFT(address indexed sender, uint256 tokenId);
    event RequestRandomness(uint256 indexed requestId);
    
    //We are inheriting from ERC721 contract, this is the constructor we are using
    constructor(
        uint64 _subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords
    ) 
    ERC721("Sentiment", "SENTI")
    VRFConsumerBaseV2(_vrfCoordinator)
    {
        // _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(MINTER_ROLE, msg.sender);

        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;

        console.log("Deployment Completed");
    }

    function mintNFT(string[WORDLIMIT] memory _words) external {
        words = _words;
        
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyHash, 
            subscriptionId, 
            requestConfirmations, 
            callbackGasLimit, 
            numWords
        );

        emit RequestRandomness(requestId);
    }

    function createSvg(string memory _sentiment, string memory _backgroundColour) internal pure returns (string memory) {
        //SVG has been split into two parts where the fill is to be entered
        //to allow for random backgrounds to be generated 
        string memory svgPart1 = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='";
        string memory svgPart2 = "'/><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";
            
        string memory svg = string(abi.encodePacked(svgPart1, _backgroundColour, svgPart2, _sentiment, "</text></svg>"));

        return svg;
    }

    function createTokenURI(string memory _sentiment, string memory _svg) internal pure returns(string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        // We set the title of our NFT as the generated word.
                        _sentiment,
                        '", "description": "Anon user names for frogs", "image": "data:image/svg+xml;base64,',
                        // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(_svg)),
                        '"}'
                    )
                )
            )
        );

         string memory tokenURI = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return tokenURI;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        console.log("Randomness received");

        uint256 currentId = _tokenIds.current();
        address newOwner = requestIdToRequester[requestId];

        uint256 randIndex1 = (randomWords[0] % WORDLIMIT) + 1;
        uint256 randIndex2 = (randomWords[1] % WORDLIMIT) + 1;
        uint256 randIndex3 = (randomWords[2] % WORDLIMIT) + 1;
        uint256 randIndex4 = (randomWords[3] % NUMCOLOURS) + 1;

        string memory word1 = words[randIndex1];
        string memory word2 = words[randIndex2];
        string memory word3 = words[randIndex3];
        string memory backgroundColour = backgroundColours[randIndex4];

        string memory combinedSentiment = string(abi.encodePacked(word1, word2, word3));
        string memory newSVG = createSvg(combinedSentiment, backgroundColour);
        string memory tokenURI = createTokenURI(combinedSentiment, newSVG);

        _safeMint(newOwner, currentId);
        _setTokenURI(currentId, tokenURI);

        console.log("New NFT has been minted with the ID of %s to the lucky: %s", currentId, newOwner);

        _tokenIds.increment();

        emit CreateNFT(newOwner, currentId);
    }

    function getCirculatingSupply() external view returns(uint256){
        return _tokenIds.current();
    }

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     override(ERC721, AccessControl)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }
}