package org.xrstudio.xmpp.flutter_xmpp.Utils;

public class Constants {

    // Result codes
    public static final int RESULT_EMPTY = 0;
    public static final int RESULT_SUCCESS = 1;
    public static final int RESULT_DEFAULT = -1;

    // General constants
    public static final String ZERO = "0";
    public static final String TRUE = "true";
    public static final String ANDROID = "Android";
    public static final String EMPTY = "";
    public static int PORT_NUMBER = 5222;

    // XMPP Constants
    public static final String TLS = "TLS";
    public static final String URN_XMPP_TIME = "urn:xmpp:time";
    public static final String URN_XMPP_CUSTOM = "urn:xmpp:custom";
    public static final String URN_XMPP_RECEIPTS = "urn:xmpp:receipts";
    public static final String URN_XMPP_DELAY = "urn:xmpp:delay";

    // Symbols
    public static final String SYMBOL_COMPARE_JID = "@";
    public static final String SYMBOL_FORWARD_SLASH = "/";
    public static final String DOT = ".";

    // Time & Date
    public static final String TS = "ts";
    public static final String TIME = "TIME";
    public static final String DATE_FORMAT = "dd-MM-yyyy HH:mm:ss.SSS";
    public static final String DELAY_TIME = "delayTime";

    // Presence
    public static final String PRESENCE = "presence";
    public static final String ONLINE = "online";
    public static final String OFFLINE = "offline";

    // Message types
    public static final String CHAT = "chat";
    public static final String GROUP_CHAT = "groupchat";
    public static final String ACK = "Ack";
    public static final String READ_ACK = "Read-Ack";
    public static final String DELIVERY_ACK = "Delivery-Ack";
    public static final String CHATSTATE = "chatstate";

    // XMPP actions
    public static final String LOGIN = "login";
    public static final String LOGOUT = "logout";
    public static final String SEND_MESSAGE = "send_message";
    public static final String SEND_GROUP_MESSAGE = "send_group_message";
    public static final String CUSTOM_MESSAGE = "send_custom_message";
    public static final String CUSTOM_GROUP_MESSAGE = "send_customgroup_message";
    public static final String CREATE_MUC = "create_muc";
    public static final String JOIN_MUC_GROUP = "join_muc_group";
    public static final String JOIN_MUC_GROUPS = "join_muc_groups";
    public static final String GET_LAST_SEEN = "get_last_seen";
    public static final String CREATE_ROSTER = "create_roster";
    public static final String GET_MY_ROSTERS = "get_my_rosters";
    public static final String GET_ONLINE_MEMBER_COUNT = "get_online_member_count";
    public static final String SEND_DELIVERY_ACK = "send_delivery_receipt";

    // XMPP groups & roles
    public static final String ADD_ADMINS_IN_GROUP = "add_admins_in_group";
    public static final String ADD_OWNERS_IN_GROUP = "add_owners_in_group";
    public static final String ADD_MEMBERS_IN_GROUP = "add_members_in_group";
    public static final String REMOVE_ADMINS_FROM_GROUP = "remove_admins_from_group";
    public static final String REMOVE_OWNERS_FROM_GROUP = "remove_owners_from_group";
    public static final String REMOVE_MEMBERS_FROM_GROUP = "remove_members_from_group";
    public static final String INVITE_MESSAGE = "Invitations to the group";

    // MUC config
    public static final String MUC_MEMBER_ONLY = "muc#roomconfig_membersonly";
    public static final String MUC_PERSISTENT_ROOM = "muc#roomconfig_persistentroom";

    // State
    public static final String STATE_UNKNOWN = "UNKNOWN";
    public static final String STATE_CONNECTED = "CONNECTED";
    public static final String STATE_CONNECTING = "CONNECTING";
    public static final String STATE_DISCONNECTED = "DISCONNECTED";
    public static final String STATE_AUTHENTICATED = "AUTHENTICATED";
    public static final String STATE_FAILED = "FAILED";
    public static final String STATE_DISCONNECTING = "DISCONNECTING";

    // Broadcast keys
    public static final String X_CREATE_MUC = "org.xrstudio.xmpp.flutter_xmpp.createMUC";
    public static final String AUTH_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.authmessage";
    public static final String READ_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.readmessage";
    public static final String X_SEND_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.sendmessage";
    public static final String RECEIVE_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.receivemessage";
    public static final String CONNECTION_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.connmessage";
    public static final String OUTGOING_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.outgoinmessage";
    public static final String PRESENCE_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.presencemessage";
    public static final String GROUP_SEND_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.sendGroupMessage";
    public static final String SUCCESS_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.successmessage";
    public static final String ERROR_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.errormessage";
    public static final String CONNECTION_STATE_MESSAGE = "org.xrstudio.xmpp.flutter_xmpp.connectionstatemessage";

    // Channels
    public static final String CHANNEL = "flutter_xmpp/method";
    public static final String CHANNEL_STREAM = "flutter_xmpp/stream";
    public static final String CHANNEL_SUCCESS_EVENT_STREAM = "flutter_xmpp/success_event_stream";
    public static final String CHANNEL_ERROR_EVENT_STREAM = "flutter_xmpp/error_event_stream";
    public static final String CHANNEL_CONNECTION_EVENT_STREAM = "flutter_xmpp/connection_event_stream";

    // Misc params
    public static final String BUNDLE_TO = "b_to";
    public static final String BUNDLE_FROM_JID = "b_from";
    public static final String BUNDLE_MESSAGE_BODY = "b_body";
    public static final String BUNDLE_PRESENCE_TYPE = "b_presence_type";
    public static final String BUNDLE_PRESENCE_MODE = "b_presence_mode";
    public static final String BUNDLE_MESSAGE_TYPE = "b_body_type";
    public static final String BUNDLE_MESSAGE_PARAMS = "b_body_params";
    public static final String BUNDLE_MESSAGE_SENDER_JID = "b_sender_jid";
    public static final String BUNDLE_MESSAGE_SENDER_TIME = "b_sender_time";
    public static final String BUNDLE_SUCCESS_TYPE = "b_success_type";
    public static final String BUNDLE_ERROR_TYPE = "b_error_type";
    public static final String BUNDLE_EXCEPTION = "b_exception";
    public static final String BUNDLE_CONNECTION_TYPE = "b_connection_type";
    public static final String BUNDLE_CONNECTION_ERROR = "b_connection_error";

    // Network / login
    public static final String HOST = "host";
    public static final String PORT = "port";
    public static final String JID_USER = "jid_user";
    public static final String USER_JID = "user_jid";
    public static final String PASSWORD = "password";
    public static final String REQUIRE_SSL_CONNECTION = "requireSSLConnection";
    public static final String USER_STREAM_MANAGEMENT = "useStreamManagement";
    public static final String AUTOMATIC_RECONNECTION = "automaticReconnection";
    public static final String AUTO_DELIVERY_RECEIPT = "autoDeliveryReceipt";

    // Misc
    public static final String ID = "id";
    public static final String BODY = "body";
    public static final String TIME_LOWER = "time";
    public static final String TO_JID = "to_jid";
    public static final String TO_JID_1 = "toJid";
    public static final String NAVIGATE_FILE_PATH = "nativeLogFilePath";
    public static final String STATUS = "status";
    public static final String TAG = "flutter_xmpp";
    public static final String OUTGOING = "outgoing";
    public static final String GROUP_ID = "group_id";
}
