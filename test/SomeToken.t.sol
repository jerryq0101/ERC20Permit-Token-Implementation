// SPDX-License-Identifier: MIT
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

// Imports
import "../src/SomeToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/SigUtilsCustom.sol";

// For accessing the internal functions of eip712
contract SomeTokenHarness is SomeToken {
    constructor() SomeToken() {}

    function _domainSeparatorV4Harness() public returns (bytes32){
        return _domainSeparatorV4();
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function getNonce(address owner) public view returns (uint256) {
        return nonces[owner];
    }
}

contract SomeTokenTest is Test {
    SomeTokenHarness someTokenHarness;
    SigUtils sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        someTokenHarness = new SomeTokenHarness();
        sigUtils = new SigUtils(someTokenHarness._domainSeparatorV4Harness());

        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        // owner as in a fund owner
        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        someTokenHarness.mint(owner, 1e18);
    }

    function test_PermitAllowance() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: 0,
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        someTokenHarness.permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        assertEq(someTokenHarness.allowance(owner, spender), 1e18);
        assertEq(someTokenHarness.getNonce(owner), 1);
    }
}


