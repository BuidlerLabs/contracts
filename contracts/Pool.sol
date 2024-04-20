pragma solidity >=0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Pool is Ownable, Pausable {
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor() Ownable(msg.sender) {

    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner whenPaused {
        merkleRoot = _merkleRoot;
        emit MerkleRootSet(_merkleRoot);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external whenNotPaused {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
        // Mark it claimed and send the token.
        _setClaimed(index);
        (bool success, ) = account.call{value: amount}("");
        require(success, 'MerkleDistributor: Transfer failed.');
        emit Claimed(index, account, amount);
    }

    function withdraw(address receiver) external onlyOwner {
        //withdraw ether
        payable(receiver).transfer(address(this).balance);
    }

    receive() external payable {}

    event Claimed(uint256 index, address account, uint256 amount);
    event MerkleRootSet(bytes32 indexed merkleRoot);
}
