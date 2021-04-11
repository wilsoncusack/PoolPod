const { expect } = require("chai");

describe("PoolPod contract", function () {

	let PoolPodContract;
	let PoolPod;
	let addr1;
  	let addr2;
  	let ERC20Token;

  	let pAsset;
  	let asset;
  	let PrizePool;

	beforeEach(async function () {
		[owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

		await deployERC20From(addr1)		
		await deployPAsset(addr1)
		await deployPrizePool(pAsset.address)

	    PoolPodContract = await ethers.getContractFactory("PoolPod");
	    pAsset.connect(addr1).transfer(PrizePool.address, BigInt(Math.pow(10, 30)))
	    
	    PoolPod = await PoolPodContract.deploy(pAsset.address, PrizePool.address, asset.address, asset.address);
	    await PoolPod.deployed();
  	});	


	describe("contribute", function () {
		it("balance = balance with no prize", async function(){
			const amount = BigInt(Math.pow(10,18));
			await contribute(addr1, amount)

			const balance = await PoolPod.balanceOf(addr1.address)
			expect(balance).to.eq(amount)
		});
	});

	describe("balanceOf", function () {
		it("0 if 0", async function(){
			const balance = await PoolPod.balanceOf(addr1.address)
			expect(balance).to.eq(BigInt(0))
		});

		it("balance = balance with no prize", async function(){
			const amount = BigInt(Math.pow(10,18));
			await contribute(addr1,amount)

			const balance = await PoolPod.balanceOf(addr1.address)
			expect(balance).to.eq(amount)
		});

		it("balance = balance + prize with prize", async function(){
			const amount = BigInt(Math.pow(10,18));
			await contribute(addr1,amount)

			const balance = await PoolPod.balanceOf(addr1.address)
			expect(balance).to.eq(amount)

			await PoolPod.commit();
			await win(amount)

			const newBalance = await PoolPod.balanceOf(addr1.address)
			expect(newBalance).to.eq(amount * BigInt(2))
		});

		it("balance = balance + prize with prize, two contributors", async function(){
			const amount = BigInt(Math.pow(10,18));
			await contribute(addr1,amount)

			const balance = await PoolPod.balanceOf(addr1.address)
			expect(balance).to.eq(amount)

			await contribute(addr2, amount)

			const balance2 = await PoolPod.balanceOf(addr2.address)
			expect(balance2).to.eq(amount)

			await PoolPod.commit();
			await win(amount)

			const newBalance = await PoolPod.balanceOf(addr1.address)
			expect(newBalance).to.eq(Math.pow(10,18) * 1.5 + "")

			const newBalance2 = await PoolPod.balanceOf(addr2.address)
			expect(newBalance2).to.eq(Math.pow(10,18) * 1.5 + "")
		});

		it("balance = balance + prize with prize, two contributors, + contributor after", async function(){
			const a = Math.pow(10,18)
			const amount = BigInt(a);
			await contribute(addr1,amount)

			const balance = await PoolPod.balanceOf(addr1.address)
			expect(balance).to.eq(amount)

			await contribute(addr2, amount)

			const balance2 = await PoolPod.balanceOf(addr2.address)
			expect(balance2).to.eq(amount)

			// await pAsset.connect(addr1).transfer(PoolPod.address, amount)
			await PoolPod.commit();
			await win(amount)

			var addr1Balance = await PoolPod.balanceOf(addr1.address)
			expect(addr1Balance).to.eq(a * 1.5 + "")

			var addr2Balance = await PoolPod.balanceOf(addr2.address)
			expect(addr2Balance).to.eq(a * 1.5 + "")

			// var b = await pAsset.balanceOf(PoolPod.address);
			// console.log(b.toString())
			await contribute(addr3, amount)
			var addr3Balance = await PoolPod.balanceOf(addr3.address)
			expect(addr3Balance).to.eq("999999999999999999")
			// b = await pAsset.balanceOf(PoolPod.address);
			// console.log(b.toString())

			addr1Balance = await PoolPod.balanceOf(addr1.address)
			expect(addr1Balance).to.eq(a * 1.5 + "")

			addr2Balance = await PoolPod.balanceOf(addr2.address)
			expect(addr2Balance).to.eq(a * 1.5 + "")
		});

		it("balance = balance + prize with prize, two contributors, + contributor after", async function(){
			const a = Math.pow(10,18)
			const amount = BigInt(a);
			await contribute(addr1,amount)

			await contribute(addr2, amount)


			// await pAsset.connect(addr1).transfer(PoolPod.address, amount)
			await PoolPod.commit();
			await win(amount)

			await contribute(addr3, amount)
			await PoolPod.commit();

			await win(amount * BigInt(3))

			addr1Balance = await PoolPod.balanceOf(addr1.address)
			expect(addr1Balance).to.eq("2625000000000000000")

			addr2Balance = await PoolPod.balanceOf(addr2.address)
			expect(addr2Balance).to.eq("2625000000000000000")

			var addr3Balance = await PoolPod.balanceOf(addr3.address)
			expect(addr3Balance).to.eq("1749999999999999998")
		});

		it("balance = balance + prize with prize, two contributors, + contributor after + fist contributor adds", async function(){
			const a = Math.pow(10,18)
			const amount = BigInt(a);
			await contribute(addr1,amount)

			await contribute(addr2, amount)


			// await pAsset.connect(addr1).transfer(PoolPod.address, amount)
			await PoolPod.commit();
			await win(amount)

			await contribute(addr3, amount)
			await PoolPod.commit();

			await win(amount * BigInt(3))

			await contribute(addr1, amount)

			addr1Balance = await PoolPod.balanceOf(addr1.address)
			expect(addr1Balance).to.eq("3624999999999999999")

			addr2Balance = await PoolPod.balanceOf(addr2.address)
			expect(addr2Balance).to.eq("2625000000000000000")

			var addr3Balance = await PoolPod.balanceOf(addr3.address)
			expect(addr3Balance).to.eq("1749999999999999998")
		});

		it("balance = balance + prize with prize, two contributors, + contributor after + fist contributor adds + another win", async function(){
			const a = Math.pow(10,18)
			const amount = BigInt(a);
			await contribute(addr1,amount)

			await contribute(addr2, amount)


			// await pAsset.connect(addr1).transfer(PoolPod.address, amount)
			await PoolPod.commit();
			await win(amount)

			await contribute(addr3, amount)
			await PoolPod.commit();

			await win(amount * BigInt(3))

			await contribute(addr1, amount)
			await win(BigInt(a * 5.5))

			addr1Balance = await PoolPod.balanceOf(addr1.address)
			expect(addr1Balance).to.eq("6117187499999999998")

			addr2Balance = await PoolPod.balanceOf(addr2.address)
			expect(addr2Balance).to.eq("4429687500000000000")

			var addr3Balance = await PoolPod.balanceOf(addr3.address)
			expect(addr3Balance).to.eq("2953124999999999997")


			await PoolPod.connect(addr1).withdraw(addr1Balance)
			await PoolPod.connect(addr2).withdraw(addr2Balance)
			await PoolPod.connect(addr3).withdraw(addr3Balance)

			addr1Balance = await PoolPod.balanceOf(addr1.address)
			expect(addr1Balance).to.eq("2")

			addr2Balance = await PoolPod.balanceOf(addr2.address)
			expect(addr2Balance).to.eq("0")

			var addr3Balance = await PoolPod.balanceOf(addr3.address)
			expect(addr3Balance).to.eq("2")
		});


	});

	describe("withdraw", function () {
		it("does not allow if exceeds balance", async function(){
			await expect(
				PoolPod.withdraw(BigInt(Math.pow(10,18)))
				).to.be.revertedWith("PoolPod: withdraw amount exceeds balance")
		});

		it("changes balance correctly", async function(){
			const amount = BigInt(Math.pow(10,18));

			await contribute(addr2, amount)

			const podBalance = await PoolPod.balanceOf(addr2.address)
			expect(podBalance).to.equal(amount)

			const assetBalance = await asset.balanceOf(addr2.address)
			expect(assetBalance).to.equal(BigInt(0))

			await PoolPod.connect(addr2).withdraw(amount)

			const newPodBalance = await PoolPod.balanceOf(addr2.address)
			expect(newPodBalance).to.equal(BigInt(0))

			const newAssetBalance = await asset.balanceOf(addr2.address)
			expect(newAssetBalance).to.equal(amount)
		});

		it("effects others correct", async function(){
			const amount = BigInt(Math.pow(10,18));

			await contribute(addr2, amount)
			await contribute(addr1, amount)

			const podBalanceAddr2 = await PoolPod.balanceOf(addr2.address)
			expect(podBalanceAddr2).to.equal(amount)

			const podBalanceAddr1 = await PoolPod.balanceOf(addr1.address)
			expect(podBalanceAddr1).to.equal(amount)

			await PoolPod.connect(addr2).withdraw(amount)

			const newPodBalanceAddr2 = await PoolPod.balanceOf(addr2.address)
			expect(newPodBalanceAddr2).to.equal(BigInt(0))

			const newPodBalanceAddr1 = await PoolPod.balanceOf(addr1.address)
			expect(newPodBalanceAddr1).to.equal(amount)
		});

	});

	async function deployERC20From(address) {
		TokenContract = await ethers.getContractFactory("ERC20Token");
	    asset = await TokenContract.connect(address).deploy();
	    await asset.deployed();
	}	

	async function deployPAsset(address) {
		TokenContract = await ethers.getContractFactory("ERC20Token");
	    pAsset = await TokenContract.connect(address).deploy();
	    await pAsset.deployed();
	}	

	async function deployPrizePool(pAsset) {
		PrizePoolContract = await ethers.getContractFactory("PrizePoolDummy");
	    PrizePool = await PrizePoolContract.deploy(pAsset, asset.address);
	    await PrizePool.deployed();
	}	

	async function contribute(address, amount) {
		if(address != addr1){
			await asset.connect(addr1).transfer(address.address, amount)
		}
		await asset.connect(address).approve(PoolPod.address, amount)

		await PoolPod.connect(address).contribute(amount)
	}

	async function win(amount){
		await asset.connect(addr1).transfer(PrizePool.address, amount)
		await pAsset.connect(addr1).transfer(PoolPod.address, amount)
	}


});