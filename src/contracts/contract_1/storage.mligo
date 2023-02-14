type user = address
type blacklist_mapping = user list

type admin_mapping = (user, bool) map
type has_paid_mapping = (user, bool) map

type collection = address * address
type collection_list = collection list

type t = {
	creator_blacklist: blacklist_mapping;
	admin_list: admin_mapping;
	has_paid: has_paid_mapping;
	collections: collection_list;
}