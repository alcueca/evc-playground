// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.19;

import "solmate/tokens/WETH.sol";
import "./VaultRegularBorrowable.sol";

/// @title VaultBorrowableWETH
/// @notice This contract extends VaultRegularBorrowable with additional feature for handling ETH deposits into a WETH
/// vault. It's an exaple of how callThroughEVCPayable modifier can be used.
contract VaultBorrowableWETH is VaultRegularBorrowable {
    WETH internal immutable weth;

    constructor(
        IEVC _evc,
        ERC20 _asset,
        IIRM _irm,
        IPriceOracle _oracle,
        ERC20 _referenceAsset,
        string memory _name,
        string memory _symbol
    ) VaultRegularBorrowable(_evc, _asset, _irm, _oracle, _referenceAsset, _name, _symbol) {
        weth = WETH(payable(address(_asset)));
    }

    /// @dev Deposits a certain amount of ETH for a receiver.
    /// @param receiver The receiver of the deposit.
    /// @return shares The shares equivalent to the deposited assets.
    function depositETH(address receiver)
        public
        payable
        virtual
        callThroughEVCPayable
        nonReentrant
        returns (uint256 shares)
    {
        address msgSender = _msgSender();

        takeVaultSnapshot();

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(msg.value)) != 0, "ZERO_SHARES");

        // Wrap received ETH into WETH.
        weth.deposit{value: msg.value}();

        _mint(receiver, shares);

        emit Deposit(msgSender, receiver, msg.value, shares);

        requireAccountAndVaultStatusCheck(address(0));
    }

    // @alcueca: I know this is an example, but for completitude I would add a `redeemToETH` function.
}
