// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BlockJobsCoin.sol";

contract CareerContract {
    address public _owner;
    BlockJobsCoin public BlockJobCoinAddress;    
    event Bought(uint256 amount);
    event Sold(uint256 amount);

    constructor(address payable _tokenContractAddress) payable{
        BlockJobCoinAddress = BlockJobsCoin(_tokenContractAddress);
        _owner = msg.sender;
    }

    // 프로젝트 경력 구조체
    struct Career{
      uint id;
      string[] roles; // 담당 포지션
      string description; // 근무 내용
      address worker; // 근로자 지갑 주소
      address company; // 신청 회사 지갑 주소
      uint stDt; // 근무 시작일
      uint fnsDt; // 근무 종료일
      uint status; // 승인 처리 상태  (0-대기, 1-승인, 2-거절)
    }

   uint public CareerTotalSupply = 1;

   mapping (uint => Career) public Career_mapping;
   mapping (address => uint[]) public CareerByWorker_mapping;
   mapping (address => uint[]) public CareerByCompany_mapping;

   event createCareer_event(address writer, uint nftId);
   event approveCareer_event(uint careerId);
   event transferFrom_event(address from, address to, uint amout);
 
    // 회원관리
    // Coin Approve;
    function approveUser(uint256 _amount) public payable {
        BlockJobCoinAddress.CoinApprove(msg.sender, address(this), _amount * (10 ** BlockJobCoinAddress.decimals()));
    }

    // 결제 및 헤드헌팅 등에 사용... 따로 불변 데이터 저장이 필요 없어보여서 클라이언트에서 분리 후 공용 사용
    function transferFrom(address _to ,uint256 _amount) public payable{
        BlockJobCoinAddress.transferFrom(msg.sender, _to, _amount * (10 ** BlockJobCoinAddress.decimals()));

        emit transferFrom_event(msg.sender, _to, _amount);
    }
    
    // 해당 주소의 BJC 토큰 소유 값 조회
    function BalanceOf(address _from) public view returns(uint256){
        return BlockJobCoinAddress.balanceOf(_from);
    }

    // 현재 컨트랙트의 이더소유 값 조회
    function GetEther() external view returns (uint256) {
        return address(this).balance;
    }

    // ETH -> BJC 스왑
    function Buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 bjcBalance = BlockJobCoinAddress.balanceOf(BlockJobCoinAddress._adminAddress());
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= bjcBalance, "Not enough tokens in the reserve");
        // eth의 (10의 5승)분의 1 이 1BRC
        BlockJobCoinAddress.transferFrom(BlockJobCoinAddress._adminAddress() , msg.sender, amountTobuy * (10 ** 5));
        emit Bought(amountTobuy);
    }

    // BJC -> ETH 스왑
    function sell(uint256 amount) payable public{
        // 최소 변환 단위보다 커야지 스왑 가능
        require(amount > 10**5, "You need to sell at least some tokens");
        // uint256 allowance = BlockJobCoinAddress.allowance(_owner, address(this));
        // require(allowance >= amount, "Check the token allowance");        
        payable(msg.sender).transfer(amount / (10 ** 5));
        BlockJobCoinAddress.transferFrom(msg.sender, address(this), amount);
        emit Sold(amount);
    }    

    // 커리어 등록
   function createCareer (string[] memory _role, string memory _description, address _company, uint _stDt, uint _fnsDt, uint256 _amount) public payable{
     // @Exception
       // require(bytes(_title).length > 9, "Title is too short"); // KOR = Letter/3bytes && ENG = Letter/1
       require(bytes(_description).length > 9, "Description is too short");

       // @Logic
       // Create NFT;
       // mintNft(_nftOwner, _nftUri);

       // Create Struct Data;
       Career_mapping[CareerTotalSupply] = Career(CareerTotalSupply, _role, _description, msg.sender, _company, _stDt, _fnsDt, 0);

       // Create Mapping Data (ByWorker)
       CareerByWorker_mapping[msg.sender].push(CareerTotalSupply);

       // Create Mapping Data (ByCompany)
       CareerByCompany_mapping[_company].push(CareerTotalSupply);

       // Transfer 관리자에게 먼저 지급;
       BlockJobCoinAddress.transferFrom(msg.sender, _owner, _amount * (10 ** BlockJobCoinAddress.decimals()));

       // emit Event
       emit createCareer_event(msg.sender, CareerTotalSupply);

       // TotalSupply Up!
       CareerTotalSupply++;
   }

   // 신청한 경력 승인 msg.sender - 회사
   function approveCareer(uint _careerId, uint _amount, uint _status) public payable{
     // @Exception
     // 커리어 아이디가 토탈 서플라이보다 크면 잘못된 아이디
     require(CareerTotalSupply > _careerId, "Bad Reuqest careerId");
     // 회사에서 맞게 Contract 보낸건지...
     require(Career_mapping[_careerId].company == msg.sender, "Not Matching Company Address");
     // 해당 커리어가 대기 상태인지. 한 번 승인하거나 거절 한 커리어는 변경이 안 됨
     require(Career_mapping[_careerId].status == 0, "already status");

     Career_mapping[_careerId].status = _status;

     // 경력 등록 거절 시에 근로자에게 30% 되돌려 줌
     if (_status == 2){
       BlockJobCoinAddress.transferFrom(_owner, Career_mapping[_careerId].worker, (_amount * (10 ** BlockJobCoinAddress.decimals())) * 3/10);
     }
     // 승인 시에 근로자가 등록할 때 admin에게 지불한 값 80%는 기업에게 배분 (가스비가...?)
     else if(_status == 1){
       BlockJobCoinAddress.transferFrom(_owner, msg.sender, (_amount * (10 ** BlockJobCoinAddress.decimals())) * 8/10);
     }

     // emit Event
     emit approveCareer_event(_careerId);
   }
  
  // 커리어 조회
   function getCareerDetail(uint _careerId) public view returns (string memory, string[] memory, address, address, uint, uint, uint){
       // @Exception
       require(CareerTotalSupply > _careerId, "Not Matched careerId");

       return(Career_mapping[_careerId].description, Career_mapping[_careerId].roles, Career_mapping[_careerId].worker, Career_mapping[_careerId].company, Career_mapping[_careerId].stDt, Career_mapping[_careerId].fnsDt, Career_mapping[_careerId].status);
   }

   // 근로자 기준으로 커리어목록 가져오기
   function getCareerByWorker(address _worker) public view returns(Career[] memory) {
       // @Exception
       // @Logic
       Career[] memory result = new Career[](CareerTotalSupply);

       // 커리어 Mapping 순회
       for (uint i=1; i < CareerTotalSupply; i++){
           // 커리어매핑 Stuct 작성자 확인;
           if(Career_mapping[i].worker == _worker){
               // result Array에 값을 넣어야한다. 하지만 memory array에 push는 불가능함으로, result[idx] = Career Sturct 형식으로 삽입.
               for(uint x=0; x < CareerByWorker_mapping[_worker].length; x++) {
                   if(result[x].id != CareerByWorker_mapping[_worker][x]) {
                       result[x] = Career(Career_mapping[i].id, Career_mapping[i].roles, Career_mapping[i].description, Career_mapping[i].worker, Career_mapping[i].company, Career_mapping[i].stDt, Career_mapping[i].fnsDt, Career_mapping[i].status);
                   }
               }
           }
       }
       return result;
   }

   // 기업 기준으로 신청받은 커리어들 가져오기
   function getCareerByComany(address _company) public view returns(Career[] memory) {
       // @Exception
       // @Logic    
       Career[] memory result = new Career[](CareerByCompany_mapping[_company].length);

       // 커리어 Mapping 순회
       for (uint i=1; i < CareerTotalSupply; i++){
           // Review Stuct Category 일치확인; (문자열비교);
           if(Career_mapping[i].company == _company){
               // result Array에 값을 넣어야한다. 하지만 memory array에 push는 불가능. 이므로, result[idx] = Review Sturct 형식으로 삽입.
               for(uint x=0; x < CareerByCompany_mapping[_company].length; x++) {
                   if(result[x].id != CareerByCompany_mapping[_company][x]) {
                       result[x] = Career(Career_mapping[i].id, Career_mapping[i].roles, Career_mapping[i].description, Career_mapping[i].worker, Career_mapping[i].company, Career_mapping[i].stDt, Career_mapping[i].fnsDt, Career_mapping[i].status);
                   }
               }
           }
       }
       return result;
   }



}
