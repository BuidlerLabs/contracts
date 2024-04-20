import {ethers} from "hardhat";
import hre from "hardhat";


async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying Proxy with account:", deployer.address);

    const XFansContract = await ethers.getContractFactory("XFans");
    const MultiCallContract = await ethers.getContractFactory("Multicall");
    const poolContractFactory = await ethers.getContractFactory("Pool");
    const poolContract = await poolContractFactory.deploy()
    const contract = await XFansContract.deploy("0x9eb08ee3f22bfe5c75fba5cdd7465ee4c162e07e",ethers.utils.parseEther("0.025")
        , ethers.utils.parseEther("0.025") , ethers.utils.parseEther("0.05"), poolContract.address);
    const multicall = await MultiCallContract.deploy();


    /*await hre.run("verify:verify", {
        address: poolContract.address,
        constructorArguments: [],
    });

    await hre.run("verify:verify", {
        address: contract.address,
        constructorArguments: [
            "0x9eb08ee3f22bfe5c75fba5cdd7465ee4c162e07e",ethers.utils.parseEther("0.05")
            , ethers.utils.parseEther("0.01") , ethers.utils.parseEther("0.04"), poolContract.address
        ],
    });*/

    console.log("Contract address:", contract.address);
    console.log("Pool address:", poolContract.address);
    console.log("Multicall address:", multicall.address);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
