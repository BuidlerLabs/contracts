pragma solidity >=0.8.20;
import "./abstract/Ownable.sol";


contract XFans is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;

    uint256 public poolFeePercent;
    address public poolFeeDestination;

    event Trade(
        address indexed trader,
        address indexed subject,
        address pool,
        bool isBuy,
        uint256 shareAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 subjectEthAmount,
        uint256 poolEthAmount,
        uint256 supply
    );

    event SetPoolFeeDestination(address indexed poolFeeDestination);
    event SetPoolFeePercent(uint256 poolFeePercent);
    event SetProtocolFeeDestination(address indexed protocolFeeDestination);
    event SetProtocolFeePercent(uint256 protocolFeePercent);
    event SetSubjectFeePercent(uint256 subjectFeePercent);
    event ShareStaked(address indexed staker, address indexed sharesSubject, uint256 amount);
    event ShareUnstaked(address indexed staker, address indexed sharesSubject, uint256 amount);


    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;
    mapping(address => mapping(address => uint256)) public stakeBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    constructor(address _protocolFeeDestination, uint256 _protocolFeePercent, uint256 _subjectFeePercent, uint256 _poolFeePercent, address _poolFeeDestination) {
        protocolFeeDestination = _protocolFeeDestination;
        protocolFeePercent = _protocolFeePercent;
        subjectFeePercent = _subjectFeePercent;
        poolFeePercent = _poolFeePercent;
        poolFeeDestination = _poolFeeDestination;
    }

    function setProtocolFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
        emit SetProtocolFeeDestination(_feeDestination);
    }

    function setProtocolFeePercent(uint256 _feePercent) public onlyOwner {
        protocolFeePercent = _feePercent;
        emit SetProtocolFeePercent(_feePercent);
    }

    function setSubjectFeePercent(uint256 _feePercent) public onlyOwner {
        subjectFeePercent = _feePercent;
        emit SetSubjectFeePercent(_feePercent);
    }

    function setPoolFeePercent(uint256 _feePercent) public onlyOwner {
        poolFeePercent = _feePercent;
        emit SetPoolFeePercent(_feePercent);
    }

    function setPoolFeeDestination(address _feeDestination) public onlyOwner {
        poolFeeDestination = _feeDestination;
        emit SetPoolFeeDestination(_feeDestination);
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        supply = supply + 1;
        uint256 sum1 = (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 160000000;
    }

    function getBuyPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], amount);
    }

    function getSellPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 poolFee = price * poolFeePercent / 1 ether;
        return price + protocolFee + subjectFee + poolFee;
    }

    function stake(address shareSubject, uint256 amount) public {
        require(sharesBalance[shareSubject][msg.sender] >= amount, "Insufficient shares");
        sharesBalance[shareSubject][msg.sender] = sharesBalance[shareSubject][msg.sender] - amount;
        stakeBalance[shareSubject][msg.sender] = stakeBalance[shareSubject][msg.sender] + amount;
        emit ShareStaked(msg.sender, shareSubject, amount);
    }

    function unstake(address shareSubject, uint256 amount) public {
        require(stakeBalance[shareSubject][msg.sender] >= amount, "Insufficient staked shares");
        stakeBalance[shareSubject][msg.sender] = stakeBalance[shareSubject][msg.sender] - amount;
        sharesBalance[shareSubject][msg.sender] = sharesBalance[shareSubject][msg.sender] + amount;
        emit ShareUnstaked(msg.sender, shareSubject, amount);
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 poolFee = price * poolFeePercent / 1 ether;
        return price - protocolFee - subjectFee - poolFee;
    }

    function buyShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 poolFee = price * poolFeePercent / 1 ether;
        require(msg.value >= price + protocolFee + subjectFee + poolFee, "Insufficient payment");
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] + amount;
        sharesSupply[sharesSubject] = supply + amount;
        emit Trade(msg.sender, sharesSubject, poolFeeDestination, true, amount, price, protocolFee, subjectFee, poolFee, supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        (bool success3, ) = poolFeeDestination.call{value: poolFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function sellShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last share");
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 poolFee = price * poolFeePercent / 1 ether;
        require(sharesBalance[sharesSubject][msg.sender] >= amount, "Insufficient shares");
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] - amount;
        sharesSupply[sharesSubject] = supply - amount;
        emit Trade(msg.sender, sharesSubject, poolFeeDestination, false, amount, price, protocolFee, subjectFee, poolFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee - poolFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        (bool success4, ) = poolFeeDestination.call{value: poolFee}("");
        require(success1 && success2 && success3 && success4, "Unable to send funds");
    }
}
