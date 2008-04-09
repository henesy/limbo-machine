Driver: module {
    T: adt {
        pick {
        Connect =>
            addr: string;
            user: string;
            db: string;
        Password =>
        }
    };

        
    R: adt {
        pick {
        Error =>
            msg: string;
        Success =>
        Request =>
        }
    };

    init: fn();
    tchan: fn(): chan of ref T;
    rchan: fn(): chan of ref R;
};
