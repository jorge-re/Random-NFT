// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RandERC721 is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string private baseTokenURI = "";
    uint private maxSupply;
    uint private counter;

    uint256 public price = 0.1 ether;
    bool public paused = true;

    address payable escrow;

    constructor(uint _maxSupply, address payable _escrow) ERC721("", "")  {
        maxSupply = _maxSupply;
        counter = _maxSupply;
        escrow = _escrow;
    }

    function pseudoRand() private returns (uint256 _rand){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }

    mapping(uint => uint) openMapping;
    function getNFT(uint intialRandom) internal{
        uint pseudoRandom = intialRandom % counter;

        if(openMapping[pseudoRandom] != 0){
            _safeMint(msg.sender, openMapping[pseudoRandom] );
        } else {
            _safeMint(msg.sender, pseudoRandom);
        }
        if(openMapping[counter-1] != 0){
            openMapping[pseudoRandom] = openMapping[counter-1];
        } else {
            openMapping[pseudoRandom] = counter-1;
        }
        counter--;
    }

    function create(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(!paused,                   "Sale paused");
        require(num <= 10,                 "You can create a maximum of 10");
        require(supply + num <= maxSupply, "Exceeds maximum supply");
        require(msg.value >= price * num,  "Ether sent is not correct");

        uint pseudoRandom = pseudoRand();

        for(uint i = 0; i < num; i++){
            uint currentValue = uint(keccak256(abi.encode(pseudoRandom, i)));
            getNFT(currentValue);
        }
    }

    function walletOfOwner(address owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokensId;
    }

    function setPrice(uint256 _price) public onlyOwner() {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function withdraw() external payable onlyOwner() {
        uint balance = address(this).balance;
        escrow.transfer(balance);
    }
}
