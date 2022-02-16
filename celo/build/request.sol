// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract RequestFactory {
    address[] internal deployedRequests;

    function createRequest(
        string memory _name,
        string memory _image,
        string memory _description,
        address payable _recipient,
        uint256 _goal
    ) public {
        address newRequestAddress = address(
            new Request(
                _name,
                _image,
                _description,
                _recipient,
                _goal,
                msg.sender
            )
        );
        deployedRequests.push(newRequestAddress);
    }

    function getDeployedRequest() public view returns (address[] memory) {
        return deployedRequests;
    }
}

contract Request {
    address internal cUsdTokenAddress =
        0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    string name;
    string image;
    string description;
    uint256 goal;
    address owner;
    bool requestComplete;
    address payable recipient;

    struct Contribution {
        address contributor;
        string message;
        uint256 amount;
    }

    mapping(uint256 => Contribution) internal contributionsList;
    uint256 contributionsLength;

    constructor(
        string memory _name,
        string memory _image,
        string memory _description,
        address payable _recipient,
        uint256 _goal,
        address _owner
    ) {
        name = _name;
        image = _image;
        description = _description;
        recipient = _recipient;
        goal = _goal;
        owner = _owner;
    }

    function getInfo()
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            uint256
        )
    {
        return (name, image, description, goal);
    }

    function contribute(string memory _message, uint256 _amount)
        public
        payable
    {
        require(!requestComplete);
        require(
            IERC20Token(cUsdTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _amount
            ),
            "Transfer failed."
        );

        contributionsList[contributionsLength] = Contribution(
            msg.sender,
            _message,
            _amount
        );

        contributionsLength++;
    }

    function getContributions(uint256 _index)
        public
        view
        returns (
            address,
            string memory,
            uint256
        )
    {
        return (
            contributionsList[_index].contributor,
            contributionsList[_index].message,
            contributionsList[_index].amount
        );
    }

    function finishRequest() public restricted {
        require(
            IERC20Token(cUsdTokenAddress).transfer(
                recipient,
                IERC20Token(cUsdTokenAddress).balanceOf(address(this))
            ),
            "Trasfer Failed"
        );
        requestComplete = true;
    }

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    function getContributionsLength() public view returns (uint256) {
        return contributionsLength;
    }

    function getBalance() public view returns (uint256) {
        return IERC20Token(cUsdTokenAddress).balanceOf(address(this));
    }
}