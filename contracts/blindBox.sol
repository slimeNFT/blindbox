//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract BlindBox is Ownable, ERC1155, Pausable {
    string public name;
    string public symbol;
    string public baseURL;

    mapping(address => bool) public minters;
    modifier onlyMinter() {
        require(minters[_msgSender()], "Mint: caller is not the minter");
        _;
    }

    struct Box {
        uint    id;
        string  name;
        uint256 mintNum;
        uint256 openNum;
        uint256 totalSupply;
    }

    mapping(uint => Box) public boxMap;

    constructor(string memory url_) ERC1155(url_) {
        name = "Slime Blind Box";
        symbol = "SBOX";
        baseURL = url_;
        minters[_msgSender()] = true;
    }

    function newBox(uint boxID_, string memory name_, uint256 totalSupply_) public onlyOwner {
        require(boxID_ > 0 && boxMap[boxID_].id == 0, "box id invalid");
        boxMap[boxID_] = Box({
            id: boxID_,
            name: name_,
            mintNum: 0,
            openNum: 0,
            totalSupply: totalSupply_
        });
    }

    function updateBox(string memory name_, uint boxID_, uint256 totalSupply_) public onlyOwner {
        require(boxID_ > 0 && boxMap[boxID_].id == boxID_, "id invalid");
        require(totalSupply_ >= boxMap[boxID_].mintNum, "totalSupply err");

        boxMap[boxID_] = Box({
            id: boxID_,
            name: name_,
            mintNum: boxMap[boxID_].mintNum,
            openNum: boxMap[boxID_].openNum,
            totalSupply: totalSupply_
        });
    }

    function mint(address to_, uint boxID_, uint num_) public onlyMinter whenNotPaused returns (bool) {
        require(num_ > 0, "mint number err");
        require(boxMap[boxID_].id != 0, "box id err");
        require(boxMap[boxID_].totalSupply >= boxMap[boxID_].mintNum + num_, "mint number is insufficient");

        boxMap[boxID_].mintNum += num_;
        _mint(to_, boxID_, num_, "");
        return true;
    }

    function mintBatch(address to_, uint[] memory boxIDs_, uint256[] memory nums_) public onlyMinter whenNotPaused returns (bool) {
        require(boxIDs_.length == nums_.length, "array length unequal");

        for (uint i = 0; i < boxIDs_.length; i++) {
            require(boxMap[boxIDs_[i]].id != 0, "box id err");
            require(boxMap[boxIDs_[i]].totalSupply >= boxMap[boxIDs_[i]].mintNum + nums_[i], "mint number is insufficient");
            boxMap[boxIDs_[i]].mintNum += nums_[i];
        }

        _mintBatch(to_, boxIDs_, nums_, "");
        return true;
    }

    function burn(address from_, uint boxID_, uint256 num_) public onlyMinter whenNotPaused {
        require(_msgSender() == from_ && isApprovedForAll(from_, _msgSender()), "burn caller is not owner nor approved");
        boxMap[boxID_].openNum += num_;
        _burn(from_, boxID_, num_);
    }

    function burnBatch(address from_, uint[] memory boxIDs_, uint256[] memory nums_) public onlyMinter whenNotPaused {
        require(_msgSender() == from_ && isApprovedForAll(from_, _msgSender()), "burn caller is not owner nor approved");
        for (uint i = 0; i < boxIDs_.length; i++) {
            boxMap[i].openNum += nums_[i];
        }
        _burnBatch(from_, boxIDs_, nums_);
    }

    function setMinter(address newMinter, bool power) public onlyOwner {
        minters[newMinter] = power;
    }

    function boxURL(uint boxID_) public view returns (string memory) {
        require(boxMap[boxID_].id != 0, "box not exist");
        return string(abi.encodePacked(baseURL, boxID_));
    }

    function setURL(string memory newURL_) public onlyOwner {
        baseURL = newURL_;
    }

    function setPause(bool isPause) public onlyOwner {
        if (isPause) {
            _pause();
        } else {
            _unpause();
        }
    }
}
