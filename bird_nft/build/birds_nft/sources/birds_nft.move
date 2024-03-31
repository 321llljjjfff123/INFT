module birds_nft::birds_nft {
    use std::option;
    use std::signer;
    use std::string;
    use std::vector;
    use std::debug::print;
    use aptos_std::string_utils;
    use aptos_std::table;
    use aptos_framework::account;
    use aptos_framework::account::SignerCapability;
    use aptos_framework::event;
    use aptos_framework::object;
    use aptos_framework::randomness;
    use aptos_framework::object::Object;

    use aptos_token_objects::collection;
    use aptos_token_objects::royalty;
    use aptos_token_objects::token;
    use aptos_token_objects::token::Token;

    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;


    const Conversion: u64 = 100000000;
    // const ERROR_NOWNER: u64 = 0;
    const MaximumPercentage: u64 = 100;


    // ERROR CODE
    const ERROR_NOWNER: u64 = 1;

    const ResourceAccountSeed: vector<u8> = b"birds";

    const CollectionDescription: vector<u8> = b"birds test.";

    const CollectionName: vector<u8> = b"birds";

    const CollectionURI: vector<u8> = b"ipfs://QmWmgfYhDWjzVheQyV2TnpVXYnKR25oLWCB2i9JeBxsJbz";

    const TokenURI: vector<u8> = b"https://nftstorage.link/ipfs/bafybeidh4smpsizbccq3pbovczucxd6rhcv2d3ygm5sifqb2gqhh2bpbza";

    const TokenPrefix: vector<u8> = b"birds #";

    const InftImage:vector<u8> = b"https://bafkreiepmehz7iuij3fmchajspu6pfs76l6ry4ck6jiyvhx4zo6t5xveuq.ipfs.nftstorage.link/";

    struct ResourceCap has key {
        cap: SignerCapability
    }

    struct CollectionRefsStore has key {
        mutator_ref: collection::MutatorRef
    }

    struct NewBirdContent has key {
        content: string::String,
        buysigner: address,
        nftaddress: string::String,
        mintv:vector<u64>

    }


    // inftjson string----------------start---------------------------------

    struct InftJson has key,store,drop{
        size:vector<u16>,
        cell: vector<u16>,
        grid: vector<u16>,
        parts: vector<PartsObject>,
        series: vector<SeriesObject>,
        type: u8,
        image:vector<u8>
    }

    struct PartsObject has key,store,drop {
        value:vector<u16>,
        img: vector<u16>,
        position: vector<u16>,
        center: vector<u16>,
        rotation: vector<u16>,
        rarity: vector<vector<u16>>
    }

    struct SeriesObject has key,store,drop {
      name:string::String,
      desc:string::String
    }
   // inftjson string-----------------end--------------------------------  

  // #[test_only]
   struct T has key {
    t: table::Table<address,u64>
   }

   struct NftV has key ,copy {
    v: vector<address>
   }


   fun creatVector(n:u64 , v: vector<u64>) : vector<u64>
     {   
        let i:u64=0;  
        while(i <= n) 
        {            
            i=i+1;  
            vector::push_back(&mut v, i);
        }; 
        v         
     }


     fun initVector(n:u64 , vectors: vector<u64>) : vector<u64>
     {   
        let i:u64=0;  
        let list = vector::empty<u64>();
        while(i <= n) 
        {            
            i=i+1;  
            vector::push_back(&mut list, commit_to_random_winners(vectors,vector::length(&vectors)));        
        }; 
        
        list     
     }

     fun commit_to_random_winners(v: vector<u64>,l:u64) :u64 {
        let r =  *vector::borrow(&v , randomly_pick_winner_internal(l));
        r
    }
 
    public(friend) fun randomly_pick_winner_internal(l:u64) : u64{   

        let winner_idx = randomness::u64_range(0, l);   
        winner_idx
    }


    fun init_module(sender: &signer) {

        let inftJson = create_nftJson();
        move_to(sender, inftJson);
        let (resource_signer, resource_cap) = account::create_resource_account(
            sender,
            ResourceAccountSeed
        );

        move_to(
            &resource_signer,
            ResourceCap {
                cap: resource_cap
            }
        );

        let collection_cref = collection::create_unlimited_collection(
            &resource_signer,
            string::utf8(CollectionDescription),
            string::utf8(CollectionName),
            option::some(royalty::create(5, 100, signer::address_of(sender))),
            string::utf8(CollectionURI)
        );

        //-------------------collection MutatorRef start ---------------

        let collection_signer = object::generate_signer(&collection_cref);

        let mutator_ref = collection::generate_mutator_ref(&collection_cref);

        move_to(
            &collection_signer,
            CollectionRefsStore {
                mutator_ref
            }
        );
        //-------------------collection MutatorRef end ---------------    

      move_to(
            &resource_signer,
            NftV {
                v: vector::empty<address>()
            }
        );

      move_to(
          &resource_signer,
          T {
               t: table::new()
          }
      );

    }

    entry public fun mint(
        sender: &signer,
        birename: string::String,
        nftaddress: string::String

    ) acquires ResourceCap {

        let resource_signer = getResource_signer();
        let url = string::utf8(TokenURI);        
        let s = string::utf8(b"bird-");
        string::append( &mut s, string::utf8(b"xxxx"));

        let token_cref = token::create_numbered_token(
            resource_signer,
            string::utf8(CollectionName),
            string::utf8(CollectionDescription),
            string::utf8(TokenPrefix),
            string::utf8(b""),
            option::none(),
            string::utf8(TokenURI)
        );    

        // create token_mutator_ref
        let token_mutator_ref = token::generate_mutator_ref(&token_cref);
        let token_signer = object::generate_signer(&token_cref);  
        let buysigner = signer::address_of(sender);    

        let vectors = creatVector(250,vector::empty<u64>());   
        let list = initVector(250,vectors);


        move_to(
            &token_signer,
            NewBirdContent {
                content:birename,
                buysigner: buysigner,
                nftaddress: nftaddress,
                mintv:list
            }
        );     

        object::transfer(
            resource_signer,
            object::object_from_constructor_ref<Token>(&token_cref),
            signer::address_of(sender),
        )

    }    


  fun match_safe_mul(a: u64, b: u64): u64 {
      let temp = a * b;
      assert!(a != 0 || b !=0, ERROR_NOWNER);
      assert!(temp / a == b, ERROR_NOWNER);
      temp
  }


    entry public fun sellBird(sender: &signer,bird_address:  address,price:u64 ) acquires NftV ,T,ResourceCap{


      let resource_signer = getResource_signer();

      //add NFTV
      let nftv = borrow_global_mut<NftV>(signer::address_of(resource_signer));
      vector::push_back(&mut nftv.v, bird_address);

      //add nttt table
      let nftt = borrow_global_mut<T>(signer::address_of(resource_signer));
      table::add(&mut nftt.t, bird_address, price);
            
      nftTransfer(sender,bird_address,signer::address_of(resource_signer));
      

    }  

    entry public fun buyBird(sender: &signer,bird_address:  address ,price:u64)  acquires NftV,T,ResourceCap {      

      let resource_signer = getResource_signer();
      let nftv = borrow_global_mut<NftV>(signer::address_of(resource_signer));
      let (findbool, findu)  = vector::index_of(&nftv.v, &bird_address);
      vector::remove(&mut nftv.v, findu);     

      let nftt = borrow_global_mut<T>(signer::address_of(resource_signer));
      let tprice = *table::borrow(&mut nftt.t, bird_address);

      assert!(tprice < price, ERROR_NOWNER);
      table::remove(&mut nftt.t, bird_address); 

      let resource_signer = getResource_signer();    
      nftTransfer(resource_signer,bird_address,signer::address_of(sender));

      let coins_nft = coin::withdraw<AptosCoin>(sender, Conversion * price *10 /100);
      // let coins_sell = coin::withdraw<AptosCoin>(sender, Conversion * price *90 /100);

      coin::deposit(signer::address_of(resource_signer), coins_nft);
      // coin::deposit(selladdredd, coins_artist);

      

    }   


    inline fun nftTransfer(owner: &signer, nft_address: address, to_address:address) {

        object::transfer(
            owner, 
            object::address_to_object<Token>(nft_address),
            to_address
        )
        
    }


    // get birds_nft resource_signer
    inline fun getResource_signer(): &signer acquires ResourceCap{

      let resource_cap = &borrow_global<ResourceCap>(
            account::create_resource_address(
                &@birds_nft,
                ResourceAccountSeed
            )
        ).cap;

      let resource_signer = &account::create_signer_with_capability(
          resource_cap
      );
      resource_signer
      
    }

    // create birds_nft_json 
    inline fun create_nftJson() : InftJson   {

       // init inftjson  string--------------------start-----------------------
      let seriesObjects = vector::empty<SeriesObject>();    

        vector::push_back(&mut seriesObjects, SeriesObject {
          name:string::utf8(b"Red"),
          desc:string::utf8(b"")
        });

        vector::push_back(&mut seriesObjects, SeriesObject {
          name:string::utf8(b"White"),
          desc:string::utf8(b"")
        });

        vector::push_back(&mut seriesObjects, SeriesObject {
          name:string::utf8(b"Green"),
          desc:string::utf8(b"")
        });

        vector::push_back(&mut seriesObjects, SeriesObject {
          name:string::utf8(b"Yellow"),
          desc:string::utf8(b"")
        });

        vector::push_back(&mut seriesObjects, SeriesObject {
          name:string::utf8(b"Blue"),
          desc:string::utf8(b"")
        });

        vector::push_back(&mut seriesObjects, SeriesObject {
          name:string::utf8(b"Colorful"),
          desc:string::utf8(b"")
        });


      let partsObjects = vector::empty<PartsObject>(); 

      let v = vector::empty<vector<u16>>();
      vector::push_back(&mut v, vector[0]);
      vector::push_back(&mut v, vector[0]);
      vector::push_back(&mut v, vector[0]);
      vector::push_back(&mut v, vector[0]);
      vector::push_back(&mut v, vector[0]);
      vector::push_back(&mut v, vector[0]);

      vector::push_back(&mut partsObjects, PartsObject {
          value:vector[0,2,1,0],
          img: vector[0,0,7,7],
          position: vector[0,0],
          center: vector[0,0],
          rotation: vector[0],
          rarity: v
        });

      let v1 = vector::empty<vector<u16>>();
      vector::push_back(&mut v1, vector[6]);
      vector::push_back(&mut v1, vector[1]);
      vector::push_back(&mut v1, vector[3]);
      vector::push_back(&mut v1, vector[5]);
      vector::push_back(&mut v1, vector[7]);
      vector::push_back(&mut v1, vector[1,3,5,6,7]);

        vector::push_back(&mut partsObjects, PartsObject {
          value:vector[4,2,8,0],
          img: vector[0,10,0,0],
          position: vector[75,180],
          center: vector[0,0],
          rotation: vector[0],
          rarity: v1
        });

        let v2 = vector::empty<vector<u16>>();
      vector::push_back(&mut v2, vector[7]);
      vector::push_back(&mut v2, vector[2]);
      vector::push_back(&mut v2, vector[4]);
      vector::push_back(&mut v2, vector[3]);
      vector::push_back(&mut v2, vector[0]);
      vector::push_back(&mut v2, vector[0,2,3,4,7]);

        vector::push_back(&mut partsObjects, PartsObject {
          value:vector[8,2,8,0],
          img: vector[0,11,0,0],
          position: vector[125,180],
          center: vector[0,0],
          rotation: vector[0],
          rarity: v2
        });


      let v3 = vector::empty<vector<u16>>();
      vector::push_back(&mut v3, vector[1]);
      vector::push_back(&mut v3, vector[5]);
      vector::push_back(&mut v3, vector[2]);
      vector::push_back(&mut v3, vector[6]);
      vector::push_back(&mut v3, vector[3]);
      vector::push_back(&mut v3, vector[1,2,3,5,6]);

        vector::push_back(&mut partsObjects, PartsObject {
          value:vector[12,2,8,0],
          img: vector[0,12,0,0],
          position: vector[175,180],
          center: vector[0,0],
          rotation: vector[0],
          rarity: v3
        });

      let v4 = vector::empty<vector<u16>>();
      vector::push_back(&mut v4, vector[4]);
      vector::push_back(&mut v4, vector[1]);
      vector::push_back(&mut v4, vector[7]);
      vector::push_back(&mut v4, vector[3]);
      vector::push_back(&mut v4, vector[5]);
      vector::push_back(&mut v4, vector[1,3,4,5,7]);

        vector::push_back(&mut partsObjects, PartsObject {
          value:vector[16,2,8,0],
          img: vector[0,13,0,0],
          position: vector[225,180],
          center: vector[0,0],
          rotation: vector[0],
          rarity: v4
        });

        let v5 = vector::empty<vector<u16>>();
      vector::push_back(&mut v5, vector[5]);
      vector::push_back(&mut v5, vector[0]);
      vector::push_back(&mut v5, vector[1]);
      vector::push_back(&mut v5, vector[7]);
      vector::push_back(&mut v5, vector[2]);
      vector::push_back(&mut v5, vector[0,1,2,5,7]);

        vector::push_back(&mut partsObjects, PartsObject {
          value:vector[20,2,8,0],
          img: vector[0,14,0,0],
          position: vector[275,180],
          center: vector[0,0],
          rotation: vector[0],
          rarity: v5
        });

        let  inftJson = InftJson{
            size: vector[400,400],
            cell: vector[50,50],
            grid: vector[8,16],
            parts: partsObjects,
            series: seriesObjects,
            type: 2,
            image:InftImage
        }; 

    // init inftjson  string--------------------end-----------------------
      inftJson   
      
    }

    // queryTable
    #[view]
    public fun queryTable() :vector<address> acquires NftV, ResourceCap{

      let resource_signer = getResource_signer(); 
      let htfvcopy = borrow_global<NftV>(signer::address_of(resource_signer));
      htfvcopy.v             

    }



   

  //  #[test(me = @0x42)]
  //  fun test2(me: &signer){
       

  //  }

   
}
