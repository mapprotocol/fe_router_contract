// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract Pool is UUPSUpgradeable,Ownable2StepUpgradeable{
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    address public router;
    mapping(address => bool) public supportTokens;

    event SetRouter(address _router);
    event UpdateSupportTokens(address _token,bool _flag);
    event Withdraw(IERC20Upgradeable _token,address _receiver,uint256 _amount);

    error ONLY_ROUTER(address _caller);
    error NOT_CONTRACT(address _contract);
    error NOT_SUPPORT(address _token);
    error ZERO_ADDRESS();

    modifier onlyRouter {
        if(msg.sender != router) revert ONLY_ROUTER(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
         _disableInitializers(); 
    }

    function initialize(address _owner) external initializer {
        __Ownable2Step_init_unchained();
        _transferOwnership(_owner);
    } 


    function setRouter(address _router) external onlyOwner {
        if(!_router.isContract()) revert NOT_CONTRACT(_router);
        router = _router;
        emit SetRouter(_router);
    }

    function updateSupportTokens(address[] calldata _tokens,bool _flag) external onlyOwner {
        uint256 len = _tokens.length;
        for (uint i = 0; i < len; i++) {
             if(!_tokens[i].isContract()) revert NOT_CONTRACT(_tokens[i]);
             supportTokens[_tokens[i]] = _flag;
             emit UpdateSupportTokens(_tokens[i],_flag);
        }
       
    }

    function withdraw(IERC20Upgradeable _token,address _recerver,uint256 _amount) external onlyOwner {
         if(_recerver == address(0)) revert ZERO_ADDRESS();
         _token.safeTransfer(_recerver,_amount); 
         emit Withdraw(_token,_recerver,_amount);
    }


    function transferTo(IERC20Upgradeable _token,address receiver,uint256 _amount) external onlyRouter {
        if(!supportTokens[address(_token)])revert NOT_SUPPORT(address(_token));
        if(receiver == address(0)) revert ZERO_ADDRESS();
        _token.safeTransfer(receiver,_amount); 
    }


    function isSupport(address _token) external view returns(bool){
        return supportTokens[_token];
    }


   /** UUPS *********************************************************/
    function _authorizeUpgrade(address) internal view override onlyOwner{
        
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }
}