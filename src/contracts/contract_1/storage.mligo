type user = address
type text = string

type tier = Moldu | Bronze | Gold | Platinum

type user_mapping = (user, (text * tier * int) ) map
type blacklist_mapping = user list

type admin_mapping = (user, bool) map
type has_paid_mapping = (user, bool) map

type collection = address * address
type collection_list = collection list

type t = {
	user_map : user_mapping;
	user_blacklist: blacklist_mapping;
	admin_list: admin_mapping;
	has_paid: has_paid_mapping;
	collections: collection_list;
}