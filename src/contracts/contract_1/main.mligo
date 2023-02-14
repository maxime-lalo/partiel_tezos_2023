#import "storage.mligo" "Storage"
#import "parameter.mligo" "Parameter"
#import "errors.mligo" "Errors"
#import "fa2_storage.mligo" "NFT_FA2_Storage"
type action =
	SetText of Parameter.set_text_param
	| NukeText of Parameter.nuke_text_param
	| AddAdmin of Parameter.add_admin_param
	| AcceptAdmin of Parameter.accept_admin_param
	| RemoveAdmin of Parameter.remove_admin_param
	| PayContractFees of Parameter.pay_contract_fees_param
	| CreateCollection of Parameter.create_collection_param
	| Reset of unit

type return = operation list * Storage.t

type ext_storage = NFT_FA2_Storage.t
type lambda_create_contract = (key_hash option * tez * ext_storage) -> (operation * address) 

// Utility functions 
let get_tier(count:int) : Storage.tier = 
	if(count < 2) then Moldu
	else if(count < 3) then Bronze
	else if(count < 4) then Gold
	else Platinum

// Assert List
let assert_admin(_assert_admin_param, store: Parameter.assert_admin_param * Storage.t) : unit =
	match  Map.find_opt(Tezos.get_sender():address) store.admin_list with
		Some (is_admin) -> 
			if is_admin then () else failwith Errors.not_admin
		| None -> failwith Errors.not_admin

let assert_blacklist(assert_blacklist_param, store : Parameter.assert_blacklist_param * Storage.t) : unit = 
	let is_blacklisted = fun (user : Storage.user) -> if(user = assert_blacklist_param) then failwith Errors.blacklisted else () in
	let _ = List.iter is_blacklisted store.user_blacklist in
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

// Contract functions
let set_text(set_text_param, store : Parameter.set_text_param * Storage.t) : Storage.t =
	let sender: address = Tezos.get_sender() in
	let user_map: Storage.user_mapping = 
		match Map.find_opt sender store.user_map with
			Some(last_entry) -> 
				let (_text, _tier, count) = last_entry in
				Map.update sender (Some(set_text_param, get_tier(count + 1), count + 1)) store.user_map
			| None -> Map.add sender (set_text_param, get_tier(1) , 1) store.user_map
		in
	{ store with user_map }

let pay_contract_fees(_pay_contract_fees_param, store : Parameter.pay_contract_fees_param * Storage.t) : Storage.t =
	let amount : tez = Tezos.get_amount() in
	let sender: address = Tezos.get_sender() in
	if(amount = 1tez) then
		match Map.find_opt sender store.has_paid with
			Some _ -> failwith Errors.fees_already_paid
			| None -> 
				let has_paid: Storage.has_paid_mapping = Map.add sender true store.has_paid in
				{store with has_paid}
	else
		failwith Errors.wrong_fees_amount
	store

// Admin functions
let nuke_text(nuke_text_param, store : Parameter.nuke_text_param * Storage.t) : Storage.t =
	match Map.find_opt nuke_text_param store.user_map with
		Some _ -> 
			let user_blacklist : Storage.blacklist_mapping = nuke_text_param :: store.user_blacklist in
			let user_map : Storage.user_mapping = Map.remove nuke_text_param store.user_map in
			{ store with user_map; user_blacklist }
		| None -> failwith Errors.text_not_found

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
		SetText (text) -> 
			let _ : unit = assert_access((), store) in
			set_text (text, store)
		| NukeText (user) -> 
			let _ : unit = assert_admin((), store) in 
			nuke_text(user, store)
		| AddAdmin (user) -> 
			let _ : unit = assert_admin((), store) in 
			add_admin(user, store)
		| AcceptAdmin _ -> accept_admin((), store)	
		| RemoveAdmin(user) -> 
			let _ : unit = assert_admin((), store) in 
			remove_admin(user, store)
		| PayContractFees _ -> pay_contract_fees((), store)
		| CreateCollection _ -> create_collection((), store)
		| Reset -> { store with user_map = Map.empty }
		in
	(([] : operation list), new_store)


// Views
[@view] let get_storage ((),s: unit * Storage.t) : Storage.t = s
