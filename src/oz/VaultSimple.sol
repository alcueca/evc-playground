// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/extensions/ERC4626.sol";
import "evc/interfaces/IVault.sol";
import "evc/interfaces/IEthereumVaultConnector.sol";

contract VaultSimple is ERC4626, IVault {
    IEVC internal immutable evc;

    constructor(
        IEVC _evc,
        IERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC4626(_asset) ERC20(_name, _symbol) {
        evc = _evc;
    }

    // [ASSIGNMENT comment]: what is the purpose of this modifier?
    modifier routedThroughEVC() {
        if (msg.sender == address(evc)) {
            _;
        } else {
            bytes memory result = evc.callback(msg.sender, 0, msg.data);

            assembly {
                return(add(32, result), mload(result))
            }
        }
    }

    // [ASSIGNMENT comment]: why the account status check might not be necessary in certain situations?
    // [ASSIGNMENT comment]: is the vault status check always necessary? why?
    modifier withChecks(address account) {
        takeSnapshot();

        _;

        if (account == address(0)) {
            evc.requireVaultStatusCheck();
        } else {
            evc.requireAccountAndVaultStatusCheck(account);
        }
    }

    // [ASSIGNMENT comment]: can this function be used to authenticate the account for the sake of the borrow-related operations? why?
    // [ASSIGNMENT comment]: if the answer to the above is "no", how this function could be modified to allow safe borrowing?
    function _msgSender() internal view virtual override returns (address) {
        if (msg.sender == address(evc)) {
            (address onBehalfOfAccount,) = evc.getCurrentOnBehalfOfAccount(address(0));
            return onBehalfOfAccount;
        } else {
            return msg.sender;
        }
    }

    // [ASSIGNMENT comment]: why this function is necessary? is it safe to unconditionally disable the controller?
    function disableController() external {
        evc.disableController(_msgSender());
    }

    // [ASSIGNMENT comment]: what is the purpose of this function?
    function checkAccountStatus(address account, address[] calldata collaterals) external returns (bytes4 magicValue) {
        require(msg.sender == address(evc), "VaultSimple: only EVC can call this function");
        require(evc.areChecksInProgress(), "VaultSimple: checks are not in progress");

        // some custom logic evaluating the account health

        // [ASSIGNMENT comment]: provide an implementation idea for this function (pseudo-code is fine), assuming that one can borrow from this vault

        return IVault.checkAccountStatus.selector;
    }

    // [ASSIGNMENT comment]: is it always necessary to take a snapshot?
    function takeSnapshot() internal {
        // some custom logic to take a snapshot
    }

    // [ASSIGNMENT comment]: what is the purpose of this function?
    // [ASSIGNMENT comment]: provide a couple use cases for this function
    function checkVaultStatus() external returns (bytes4 magicValue) {
        require(msg.sender == address(evc), "VaultSimple: only EVC can call this function");
        require(evc.areChecksInProgress(), "VaultSimple: checks are not in progress");

        // some custom logic evaluating the vault health using the snapshot

        // reset the snapshot

        return IVault.checkVaultStatus.selector;
    }

    function transfer(
        address to,
        uint256 value
    ) public virtual override (ERC20, IERC20) routedThroughEVC withChecks(_msgSender()) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override (ERC20, IERC20) routedThroughEVC withChecks(from) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override routedThroughEVC withChecks(address(0)) returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual override routedThroughEVC withChecks(address(0)) returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override routedThroughEVC withChecks(owner) returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual override routedThroughEVC withChecks(owner) returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    // [ASSIGNMENT code]: extend and rework this smart contract to support borrowing functionality
    // [ASSIGNMENT code]: the following functions must be added: borrow, repay, liquidate
    // [ASSIGNMENT code]: the following functions must be overridden: disableController, checkAccountStatus, _convertToShares, _convertToAssets, maxWithdraw, maxRedeem
    // [ASSIGNMENT code]: optional functionality to be added: pullDebt/transferDebt
    // [ASSIGNMENT code]: optional functionality to be added: interest accrual
    // [ASSIGNMENT code]: optional functionality to be added: circuit breaker-like checkVaultStatus, may be EIP-7265 inspired
    // [ASSIGNMENT code]: optional functionality to be added: EIP-7540 compatibility for RWAs
}
