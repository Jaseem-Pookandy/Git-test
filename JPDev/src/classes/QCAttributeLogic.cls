public class QCAttributeLogic {

	public Boolean isVisible {get; set;}
    public Boolean isEditable {get; set;}

    public QCAttributeLogic(Boolean vis, Boolean edit) {
        this.isVisible = vis;
        this.isEditable = edit;
    }    
}