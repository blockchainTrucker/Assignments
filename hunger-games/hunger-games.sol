//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract Math {
    function add(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function randomness(uint256 remaining) internal view returns (uint256) {
        uint256 time = block.timestamp;
        (, uint256 randomNumber) = mod(time, remaining);
        return randomNumber;
    }
}

contract Capitol is Math {
    address owner;
    uint256 startTime;
    string[12] districts = ["district1","district2","district3","district4","district5","district6","district7","district8","district9","district10","district11","district12"];

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Must be the contract owner");
        _;
    }

    event EntryCreated(string entryCreated);

    event Started(string started);

    event Remaining(uint256 remaining);

    event Check(string message,uint256 remaining);

    event GetWinner(string name, string district);

    struct DistrictEntries {
        string district;
        string name;
        uint age;
        string gender;
        bool alive;
    }

    DistrictEntries[] districtEntries;

    function entryChecker(uint age, string memory district, string memory gender) internal view returns(bool) {
        bool male;
        bool female;
        bool allowDistrict;
        for(uint i = 0; i < districts.length; i++) {
            if(keccak256(abi.encodePacked(districts[i])) == keccak256(abi.encodePacked(district))) {
                allowDistrict = true;
            }
        }
        require(allowDistrict == true, "District not approved");
        require(age >= 13 && age <= 18, "Only ages 13-18 allowed");
        for(uint i = 0; i < districtEntries.length; i++) {
            if(keccak256(abi.encodePacked(districtEntries[i].district)) == keccak256(abi.encodePacked(district))) {
                if(keccak256(abi.encodePacked(districtEntries[i].gender)) == keccak256(abi.encodePacked("male"))) {
                    male = true;
                }
                if(keccak256(abi.encodePacked(districtEntries[i].gender)) == keccak256(abi.encodePacked("female"))) {
                    female = true;
                }
            }
        }
        require(male == false || female == false, "This district already has 2 entries");
        require(keccak256(abi.encodePacked(gender)) == keccak256(abi.encodePacked("male")) || keccak256(abi.encodePacked(gender)) == keccak256(abi.encodePacked("female")), "Participant must be a male or female");
        if(keccak256(abi.encodePacked(gender)) == keccak256(abi.encodePacked("male"))) {
            require(male == false, "District already has a male participant");
        }
        if(keccak256(abi.encodePacked(gender)) == keccak256(abi.encodePacked("female"))) {
            require(female == false, "District already has a female participant");
        }
        return true;
    }

    function aliveFighters() public returns(uint256) {
        uint timeLeft = timeRemaining();
        require(startTime > 0, "The game hasn't begun");
        require(timeLeft > 0, "Time has expired... The game is over");
        uint256 numberAlive;
        for(uint i = 0; i < districtEntries.length; i++) {
            if(districtEntries[i].alive == true) {
                (, numberAlive) = add(numberAlive, 1);
            }
        }
        emit Remaining(numberAlive);
        return numberAlive;
    }

    function districtEntry(string memory district, string memory name, uint age, string memory gender) public returns(bool) {
        require(startTime == 0, "Registration has closed");
        bool response = entryChecker(age, district, gender);
        require(response == true, "Entry does not meet requirements");
        districtEntries.push(DistrictEntries(district, name, age, gender, true));
        emit EntryCreated("entry created");
        return true;
    }

    function commence() public onlyOwner {
        require(districtEntries.length == 24, "Not enough fighters to begin");
        startTime = block.timestamp;
        emit Started("started");
    }

    function timeRemaining() public view returns(uint256 secondsRemaining) {
        require(startTime > 0, "The game hasn't begun");
        (, uint256 endtime) = add(startTime, 300);
        (, uint256 timeLeft) = sub(endtime, block.timestamp);
        return timeLeft;
    }

    function killFighter() internal returns(string memory deadFighter, uint256 remainingFighters) {
        require(startTime > 0, "The game hasn't begun");
        uint fightersLeft = aliveFighters();
        uint256 randomNumber = randomness(fightersLeft);
        deadFighter = districtEntries[randomNumber].name;
        districtEntries[randomNumber].alive = false;
        remainingFighters = aliveFighters();
        return (deadFighter, remainingFighters);
    }

    function check() public returns(string memory fighterDied, uint fightersRemaining) {
        uint256 firstRemainingFighters = aliveFighters();
        uint256 timeLeft = timeRemaining();
        require(timeLeft > 0, "Time has expired... The game is over");
        if(firstRemainingFighters > 1) {
            (string memory deadFighter, uint remainingFighters) = killFighter();
            firstRemainingFighters = remainingFighters;
            emit Check(deadFighter, remainingFighters);
            return (deadFighter, remainingFighters);
        } else {
            emit Check("The competition is over", firstRemainingFighters);
            return ("The competition is over", firstRemainingFighters);
        }
    }

    function getWinner() public returns(string memory name, string memory district) {
        uint256 remainingFighters = aliveFighters();
        uint256 remaingTime = timeRemaining();
        string memory winnerName;
        string memory winnerDistrict;
        require(remainingFighters == 1 && remaingTime == 0, "The competition is not over yet.");
        if(remainingFighters > 1 && remaingTime == 0) {
            (, uint amountToKill) = sub(remainingFighters , 1);
            uint i = 0;
            while(i != amountToKill) {
                killFighter();
                i++;
            }
        }
        for(uint i = 0; i < districtEntries.length; i++) {
            if(districtEntries[i].alive == true) {
                emit GetWinner(winnerName, winnerDistrict);
                return (winnerName, winnerDistrict);
            }
        }
    }
}