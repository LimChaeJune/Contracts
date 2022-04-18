// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./BlockJobsCoin.sol"
import "./BlockJobsNft.sol"

contract CarrerContract {
    BlockJobsNft public BlockJobNftAddress;
    BlockJobsCoin public BlockJobCoinAddress;

    constructor(address payable _tokenContractAddress, address payable _nftContractAddress){
        BlockJobCoinAddress = BlockJobsCoin(_tokenContractAddress);
        BlockJobNftAddress = BlockJobsNft(_nftContractAddress);
    }

    // 프로젝트 경력 구조체
    struct Career{
      uint id;
      string[] role; // 담당 포지션
      address worker; // 근로자 지갑 주소
      address company; // 신청 회사 지갑 주소
      uint stDt; // 근무 시작일
      uint fnsDt; // 근무 종료일
      uint nftId;
      uint price;
      uint status // 승인 처리 상태  (0-대기, 1-승인, 2-거절)
    }

   uint public CareerTotalSupply = 1;

   mapping (uint => ProjectCareer) public Career_mapping;
   mapping (address => uint[]) public CareerByWorker_mapping;
   mapping (address => uint[]) public CareerByCompany_mapping;

   event createCareer_event(address writer, uint nftId);
   event approveCareer_event(uint careerId);

    // NFT Approve;
   function approveForNFT(address _tokenOwner) public payable {
       BlockJobNftAddress.approveForAll(_tokenOwner, address(this));
   }

   function createCareer (string[] _role, address _company, uint _stDt, uint _fnsDt, string _nftUri, address _admin, uint _amount) public payable{
     // @Exception
       require(bytes(_title).length > 9, "Title is too short"); // KOR = Letter/3bytes && ENG = Letter/1
       require(bytes(_des).length > 9, "Description is too short");

       // @Logic
       // Create NFT;
       mintNft(_nftOwner, _nftUri);

       // Create Struct Data;
       address[] memory liked;
       Career_mapping[TotalSupply] = Career(CareerTotalSupply, _role, _msgSender(), _company, _stDt, _fnsDt, projectCareerTotalSupply, 0, 0);

       // Create Mapping Data (ByWorker)
       CareerByWorker_mapping[_msgSender()].push(CareerTotalSupply);

       // Create Mapping Data (ByCompany)
       CareerByCompany_mapping[_company].push(CareerTotalSupply);

       // Transfer;
       BlockJobCoinAddress.transferFrom(_msgSender(), _admin, _amount);

       // emit Event
       emit createCareer_event(_msgSender(), CareerTotalSupply);

       // TotalSupply Up!
       CareerTotalSupply++;
   }

   // 신청한 경력 승인 _msgSender - 회사
   function approveCareer(uint _careerId, address _admin, uint _amount, uint _status) public payable{
     // 커리어 아이디가 토탈 서플라이보다 작으면
     require(CareerTotalSupply > _careerId, "Bad Reuqest careerId");
     require(Career_mapping[_careerId].company == _msgSender(), "Not Matching Company Address");
     require(Career_mapping[_careerId].status == 0, "already status");

     Career_mapping[_careerId].status = _status;

     // 경력 등록 거절 시에 근로자에게 30% 되돌려 줌
     if (_status == 2){
       BlockJobCoinAddress.transferFrom(_admin, Career_mapping[_careerId].worker, _amount * 3/10);
     }
     // 승인 시에 근로자가 등록할 때 admin에게 지불한 값 80%는 기업에게 배분
     else if(_status == 1){
       BlockJobCoinAddress.transferFrom(_admin, _msgSender(), _amount * 8/10);
     }

     // emit Event
     emit approveCareer_event(_careerId);
   }

   function getCareerDetail(uint _careerId) public view returns (string memory, string memory, address, address[] memory, uint, string memory, uint){
          require(CareerTotalSupply > _careerId, "No Reviews");
          return();
   }

   // 근로자 기준으로 커리어 가져오기
   function getCareerByWorker(address _worker) public view returns(Career[] memory) {
       // @Exception
       // @Logic
       Career[] memory result = new Career[](careerTotalSupply);

       // Review Mapping 순회
       for (uint i=1; i < CareerTotalSupply; i++){
           // Review Stuct Writer 일치확인;
           if(Review_mapping[i].worker == worker){
               // 왜 reviewByWriter_mapping로 바로 반환 안할까?
               for(uint x=0; x < reviewByWriter_mapping[_writer].length; x++) {
                   if(result[x].id != reviewByWriter_mapping[_writer][x]) {
                       result[x] = Review(Review_mapping[i].id, Review_mapping[i].title, Review_mapping[i].description, Review_mapping[i].writer, Review_mapping[i].likedUser, Review_mapping[i].nftId, Review_mapping[i].price, Review_mapping[i].category, Review_mapping[i].createdAt);
                   }
               }
           }
       }
       return result;
   }

   // 기업 기준으로 신청받은 커리어들 가져오기
   function getCareerByComany(string memory _category) public view returns(Review[] memory) {
       // @Exception
       // @Logic
       Review[] memory result = new Review[](reviewByCategory_mapping[_category].length);

       // Review Mapping 순회
       for (uint i=1; i < TotalSupply; i++){
           // Review Stuct Category 일치확인; (문자열비교);
           if(keccak256(bytes(Review_mapping[i].category)) == keccak256(bytes(_category))){
               // result Array에 값을 넣어야한다. 하지만 memory array에 push는 불가능. 이므로, result[idx] = Review Sturct 형식으로 삽입.
               for(uint x=0; x < reviewByCategory_mapping[_category].length; x++) {
                   if(result[x].id != reviewByCategory_mapping[_category][x]) {
                       result[x] = Review(Review_mapping[i].id, Review_mapping[i].title, Review_mapping[i].description, Review_mapping[i].writer, Review_mapping[i].likedUser, Review_mapping[i].nftId, Review_mapping[i].price, Review_mapping[i].category, Review_mapping[i].createdAt);
                   }
               }
           }
       }
       return result;
   }

   // NFT 생성;
   function mintNft(address _owner, string memory _tokenURI) internal {
       // @Logic
       BlockJobNftAddress.minting(_owner, _tokenURI, TotalSupply);
   }

   // NFT 조회;
  function getNftOwnerOf(uint _nftId) public view returns(address){
      return BlockJobNftAddress.ownerOf(_nftId);
  }

  // tokenURI 조회
  function getNftTokenUri(uint _nftId) public view returns(string memory){
      return BlockJobNftAddress.tokenURI(_nftId);
  }

  function getNftBalanceOf(address _owner) public view returns(uint){
      return BlockJobNftAddress.balanceOf(_owner);
  }

  // 판매등록
  function registerForSale(uint _tokenId, uint _price) public payable {
      // @Exception
      // _owner == msg.sender냐?
      require(getNftOwnerOf(_tokenId) == _msgSender(), "Your Not Owner of NFT");

      // @Logic
      // Review Struct의 price를 변경해라 !
      Review_mapping[_tokenId].price = _price;
  }

    // 판매철회
    function withdrawFromSale(uint _tokenId) public payable {
        // @Exception
        // _owner == msg.sender냐?
        require(getNftOwnerOf(_tokenId) == _msgSender(), "Your Not Owner of NFT");

        // @Logic
        Review_mapping[_tokenId].price = 0;
    }


    // Transfer (호출자 : 구매자)
    function saleNFT(address _owner, address _buyer, uint _tokenId, uint _amount) public payable {
        // @Exception
        // Owner Cannot Call
        require(_owner != _msgSender(), "You are the owner of NFT");
        // Review Price = 0보다 크냐?
        require(Review_mapping[_tokenId].price > 0, "It is not OnSALE");
        // _amount = Review Price 랑 같냐?
        require(_amount == Review_mapping[_tokenId].price, "Your Amount is not matched with price");

        // @Logic
        // Transfer NFT
        reviewNftAddress.safeTransferFrom(_owner, _buyer, _tokenId);

        // Review Writer Update;
        Review_mapping[_tokenId].writer = getNftOwnerOf(_tokenId);
        // 구매자 계정에서 추가
        reviewByWriter_mapping[_buyer].push(_tokenId);
        // 판매자 계정에서 삭제
        for(uint i=0; i < reviewByWriter_mapping[_owner].length; i++){
            if(reviewByWriter_mapping[_owner][i] == _tokenId){
                delete reviewByWriter_mapping[_owner][i];
            }
        }

        // Token 보내기;
        reviewCoinAddress.transferFrom(_msgSender(), _owner, _amount);

        // 거래 성사시, price 0으로 초기화;
        Review_mapping[_tokenId].price = 0;

        emit tradeNft_event(_owner, _buyer, _tokenId);
    }

}
