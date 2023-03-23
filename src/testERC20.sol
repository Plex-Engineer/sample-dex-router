pragma solidity ^0.8.18;

import "solmate/tokens/ERC20.sol";

contract TestERC20 is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        _mint(msg.sender, 10000000000000000000 ether);
    }
}
