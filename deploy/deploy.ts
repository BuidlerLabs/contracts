import {ethers} from "hardhat";


async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying Proxy with account:", deployer.address);

    const XFansContract = await ethers.getContractFactory("XFans");
    const contract = await XFansContract.deploy("0x9eb08ee3f22bfe5c75fba5cdd7465ee4c162e07e",ethers.utils.parseEther("0.05")
        , ethers.utils.parseEther("0.01") , ethers.utils.parseEther("0.04"), "0x9eb08ee3f22bfe5c75fba5cdd7465ee4c162e07e");

    console.log("Contract address:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
