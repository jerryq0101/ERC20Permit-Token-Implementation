// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./SigUtilsCustom.sol";

contract SomeToken is EIP712, ERC20 {
    mapping(address => uint256) internal nonces;

    constructor() ERC20("SomeToken", "ST") EIP712("SomeToken", "1") {
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SomeToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonces[owner],
                deadline
            )
        );

        bytes32 hashbrown = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hashbrown, v, r, s);

        require(signer == owner, "Permit: Not owner's signature");
        require(signer != address(0), "ECDSA: Invalid Signature");

        require(block.timestamp < deadline, "Permit: Expired");
        nonces[owner]++;

        _approve(owner, spender, value);
    }
}