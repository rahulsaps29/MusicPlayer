
import UIKit
import MediaPlayer

class ListViewController: UIViewController {
    
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mediaItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! MusicTableViewCell
        cell.songName.text = mediaItems[indexPath.row].title!
        cell.songAlbum.text = mediaItems[indexPath.row].albumTitle
        if cell.songAlbum.text == ""{
            cell.songAlbum.text = "Unknown"
        }
        let url = mediaItems[indexPath.row].value(forProperty: MPMediaItemPropertyAssetURL) as! URL
        let item = AVPlayerItem(url: url)
        let info = item.asset.metadata
        cell.artwork.image = UIImage(named: "placeholder")
        for item in info {
            if item.commonKey  == "artwork" {
                cell.artwork.image = UIImage(data: item.value as! Data)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView!, didSelectRowAtIndexPath indexPath: IndexPath!) {
        performSegue(withIdentifier: "playMusic", sender: self)
    }


    @IBAction func onTouchBackButton(_ sender: UIButton) {
       _ = navigationController?.popToRootViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playMusic"{
            if let index = tableView.indexPathsForSelectedRows?[0].item{
                if let destination = segue.destination as? ViewController{
                    destination.playFlag = true
                    destination.playItem = index
                    soundPlayer?.stop()
                }
            }
        }
    }
}
