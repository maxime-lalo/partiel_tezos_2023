#import "storage.mligo" "Storage"
#import "parameter.mligo" "Parameter"
#import "errors.mligo" "Errors"
#import "fa2_storage.mligo" "NFT_FA2_Storage"
type action =
	AddAdmin of Parameter.add_admin_param
	| AcceptAdmin of Parameter.accept_admin_param
	| RemoveAdmin of Parameter.remove_admin_param
	| PayContractFees of Parameter.pay_contract_fees_param
	| CreateCollection of Parameter.create_collection_param
	| Reset of unit

type return = operation list * Storage.t

type ext_storage = NFT_FA2_Storage.t
type lambda_create_contract = (key_hash option * tez * ext_storage) -> (operation * address) 

// Assert List
let assert_admin(_assert_admin_param, store: Parameter.assert_admin_param * Storage.t) : unit =
	match  Map.find_opt(Tezos.get_sender():address) store.admin_list with
		Some (is_admin) -> 
			if is_admin then () else failwith Errors.not_admin
		| None -> failwith Errors.not_admin

let assert_blacklist(_assert_blacklist_param, store : Parameter.assert_blacklist_param * Storage.t) : unit = 
	let is_blacklisted = fun (user : Storage.user) -> if(user = Tezos.get_sender()) then failwith Errors.blacklisted else () in
	let _ = List.iter is_blacklisted store.creator_blacklist in
	()

let assert_access(_assert_access_param, store: Parameter.assert_access_param * Storage.t) : unit =
	match  Map.find_opt(Tezos.get_sender()) store.has_paid with
		Some (has_access) -> 
			if has_access then () else failwith Errors.fees_not_paid
		| None -> failwith Errors.fees_not_paid

// Admin management
let add_admin(add_admin_param, store: Parameter.add_admin_param * Storage.t) : Storage.t = 
	let admin_list : Storage.admin_mapping = 
		match Map.find_opt add_admin_param store.admin_list with
			Some _ -> failwith Errors.invitation_already_sent
			| None -> Map.add add_admin_param false store.admin_list
		in
	{ store with admin_list }

let accept_admin(_accept_admin_param, store: Parameter.accept_admin_param * Storage.t) : Storage.t =
	let sender : address = Tezos.get_sender() in
	let admin_list : Storage.admin_mapping = 
		match Map.find_opt sender store.admin_list with
			Some _ -> Map.update sender (Some(true)) store.admin_list
			| None -> failwith Errors.no_admin_invitation
		in
	{ store with admin_list }

let remove_admin(remove_admin_param, store: Parameter.remove_admin_param * Storage.t) : Storage.t = 
	let sender:address = Tezos.get_sender() in
	if(sender = remove_admin_param) then 
		failwith Errors.cant_remove_self_admin
	else
		let admin_list : Storage.admin_mapping = 
			match Map.find_opt remove_admin_param store.admin_list with
				Some _ -> Map.remove remove_admin_param store.admin_list
				| None -> failwith Errors.wasnt_admin
			in
		{ store with admin_list }

let pay_contract_fees(_pay_contract_fees_param, store : Parameter.pay_contract_fees_param * Storage.t) : Storage.t =
	let amount : tez = Tezos.get_amount() in
	let sender: address = Tezos.get_sender() in
	if(amount >= 10tez) then
		match Map.find_opt sender store.has_paid with
			Some _ -> failwith Errors.fees_already_paid
			| None -> 
				let has_paid: Storage.has_paid_mapping = Map.add sender true store.has_paid in
				{store with has_paid}
	else
		failwith Errors.wrong_fees_amount
	store

let create_collection(_create_collection_param, store : Parameter.create_collection_param * Storage.t) : Storage.t =
    let sender = Tezos.get_sender() in
	let initial_storage: ext_storage = {
		ledger = Big_map.empty;
		token_metadata = Big_map.empty;
		operators = Big_map.empty;
		metadata = Big_map.empty;
	} in
    let create_my_contract () : (operation * address) =
      [%Michelson ( {| {
            UNPAIR ;
            UNPAIR ;
            CREATE_CONTRACT
#include "./FA2_NFT.tz"
               ;
            PAIR } |}
              : lambda_create_contract)] ((None : key_hash option), 0tez, initial_storage)
    in
    let originate : operation * address = create_my_contract() in
	let collections : Storage.collection_list = (sender, originate.1) :: store.collections in
    { store with collections }

// Main
let main (action, store : action * Storage.t) : return =
	let new_store : Storage.t = match action with
		| AddAdmin (user) -> 
			let _ : unit = assert_admin((), store) in 
			add_admin(user, store)
		| AcceptAdmin _ -> accept_admin((), store)	
		| RemoveAdmin(user) -> 
			let _ : unit = assert_admin((), store) in 
			remove_admin(user, store)
		| PayContractFees _ -> pay_contract_fees((), store)
		| CreateCollection _ -> 
			let _ : unit = assert_access((), store) in	
			let _ : unit = assert_blacklist((), store) in	
			create_collection((), store)
		| Reset -> { store with creator_blacklist = []; admin_list = Map.empty; has_paid = Map.empty; collections = [] }
		in
	(([] : operation list), new_store)


// Views
[@view] let get_storage ((),s: unit * Storage.t) : Storage.t = s
[@view] let get_collections ((), s : unit * Storage.t) : Storage.collection_list = s.collections
