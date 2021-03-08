// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

pragma abicoder v2;

import "./Context.sol";

contract NLC is Context {

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address private _LIQUIDITY_TRANSFORMER;
    address private _liquidityGateKeeper;  

    address private _STAKE_TRANSFORMER;
    address private _stakeGateKeeper;
    bool private _stakeAccess;

    struct TokenTransfer {
        address recipient;
        uint256 amount;
    }

    /**
     * @dev initial private
     */
    string private _name;
    string private _symbol;
    uint8 private _decimal = 8;
    address private _swapAdmin;

    /**
     * @dev 👻 Initial supply 
     */
    uint256 private _totalSupply = 0;

    /**
     * @dev Maximum supply 
     */
    uint256 private maxSupply = 103437734400000000;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor (address swapAdmin) {
        _name = "NoLimitCoin";
        _symbol = "NLC";
        _swapAdmin = swapAdmin;
        _liquidityGateKeeper = msg.sender;
        _stakeGateKeeper = msg.sender; 
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimal;
    }

    /**
     * @dev Returns the total supply of the token.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the token balance of specific address.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Allows to transfer tokens 
     */
    function transfer(
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _transfer(
            _msgSender(),
            recipient,
            amount
        );

        return true;
    }

    /**
     * @dev Returns approved balance to be spent by another address
     * by using transferFrom method
     */
    function allowance(
        address owner,
        address spender
    )
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev Sets the token allowance to another spender
     */
    function approve(
        address spender,
        uint256 amount
    )
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            amount
        );

        return true;
    }

    /**
     * @dev Allows to transfer tokens on senders behalf
     * based on allowance approved for the executer
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
        public
        returns (bool)
    {
        _approve(sender,
            _msgSender(), _allowances[sender][_msgSender()].sub(
                amount
            )
        );

        _transfer(
            sender,
            recipient,
            amount
        );
        return true;
    }

    /**
     * @dev Allows to transfer tokens to multiple accounts
     */
    function transferToMultipleAccounts(
        TokenTransfer[] memory _account 
    )
        public
        returns (bool)
    {   
        require(
            _account.length <= 10, 
            'NLC: more than 10 transfers are not allowed in single transaction'
        );

        for (uint8 _i = 0; _i < _account.length; _i++) {

            _transfer(
                _msgSender(),
                _account[_i].recipient,
                _account[_i].amount
            );

        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * Emits a {Transfer} event.
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            sender != address(0x0)
        );

        require(
            recipient != address(0x0)
        );

        _balances[sender] =
        _balances[sender].sub(amount);

        _balances[recipient] =
        _balances[recipient].add(amount);

        emit Transfer(
            sender,
            recipient,
            amount
        );
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(
        address account,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            account != address(0x0)
        );

        require(
            _totalSupply.add(amount) <= maxSupply,
            'NLC: mint amount exceeds maximum supply limit'
        );

        _totalSupply =
        _totalSupply.add(amount);

        _balances[account] =
        _balances[account].add(amount);

        emit Transfer(
            address(0x0),
            account,
            amount
        );
    }


    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(
        address account,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            account != address(0x0)
        );

        _balances[account] =
        _balances[account].sub(amount);

        _totalSupply =
        _totalSupply.sub(amount);

        emit Transfer(
            account,
            address(0x0),
            amount
        );
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    )
        internal
        virtual
    {
        require(
            owner != address(0x0)
        );

        require(
            spender != address(0x0)
        );

        _allowances[owner][spender] = amount;

        emit Approval(
            owner,
            spender,
            amount
        );
    }

    /**
     * @notice ability to define liquidity transformer address
     * @dev this method renounce _liquidityGateKeeper access
     * @param _immutableTransformer contract address
     */
    function setLiquidityTransformer(
        address _immutableTransformer
    )
        external
    {
        require(
            _liquidityGateKeeper == msg.sender,
            'NLC: transformer defined'
        );
        _LIQUIDITY_TRANSFORMER = _immutableTransformer;
        _liquidityGateKeeper = address(0x0);
    }

    /**
     * @notice ability to define stake transformer contract
     * @param _immutableTransformer contract address
     */
    function setStakeTransformer(
        address _immutableTransformer
    )
        external
    {
        require(
            _stakeGateKeeper == msg.sender,
            'NLC: transformer defined'
        );

        _STAKE_TRANSFORMER = _immutableTransformer;
        _stakeAccess = true;
    }

    /**
     * @notice ability to renounce _stakeGateKeeper access 
     * after giving access to staking contract
     */
    function revokeAccess()
        external
    {
        require(
            _stakeGateKeeper == msg.sender,
            'NLC: transformer defined'
        ); 

        require(
            _stakeAccess == true,
            'NLC: access is not given to staking contract'
        ); 

        _stakeGateKeeper = address(0x0);  
    }    

    /**
     * @notice allows liquidityTransformer to mint supply to swap admin's account 
     * @dev executed from liquidityTransformer upon NLC2 transfer
     * and payout to contributors by swap admin
     * @param _amount of tokens to mint for _investorAddress
     */
    function mintSupplyToSwapAdmin(
        uint256 _amount
    )
        external
    {
        require(
            (msg.sender == _LIQUIDITY_TRANSFORMER),
            'NLC: wrong transformer'
        );

        _mint(
            _swapAdmin,
            _amount
        );
    }

    /**
     * @notice allows stakeTransformer to mint supply
     * @dev executed from stakeTransformer to payout investors
     * @param _investorAddress address for minting NLCtokens
     * @param _amount of tokens to mint for _investorAddress
     */
    function mintSupply(
        address _investorAddress,
        uint256 _amount
    )
        external
    {
        require(
            (msg.sender == _STAKE_TRANSFORMER),
            'NLC: wrong transformer'
        );

        _mint(
            _investorAddress,
            _amount
        );
    }

    /**
     * @notice allows stakeTransformer to burn supply
     * @dev executed from stakeTransformer upon NLC stake
     * @param _investorAddress address for burning NLC tokens
     * @param _amount of tokens to burn for _investorAddress
     */
    function burnSupply(
        address _investorAddress,
        uint256 _amount
    )
        external
    {
        require(
            msg.sender == _STAKE_TRANSFORMER ,
            'NLC: wrong transformer'
        );

        _burn(
            _investorAddress,
            _amount
        );
    }

    /**
     * @dev Allows to burn tokens if token sender
     * wants to reduce totalSupply() of the token
     */
    function burn(
        uint256 amount
    )
        external
    {
        _burn(msg.sender, amount);
    }
    
}
