

import UIKit

class MusicTableViewCell: UITableViewCell {
    
    @IBOutlet weak var artwork: UIImageView!
    
    @IBOutlet weak var songName: UILabel!
    
    @IBOutlet weak var songAlbum: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
