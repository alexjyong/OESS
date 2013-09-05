<script>

function Cookie(){

  this.data = {};

  this.load = function(){
	  var cookies = document.cookie.split("; ");
      var workgroup_id = YAHOO.util.History.getQueryStringParameter('workgroup_id');

      var circuit_id = YAHOO.util.History.getQueryStringParameter('circuit_id');
	  for (var i = 0; i < cookies.length; i++){

		  var candidate = cookies[i];

		  var kvpair = candidate.split("=");

		  if (kvpair[0] == "data"){
		      this.data = JSON.parse(decodeURIComponent(kvpair[1]));
		  }

		}


        if (location.href.match(/action=index/ && workgroup_id) ){
            this.data.workgroup_id = workgroup_id;

        }
        if (location.href.match(/action=view_details/ && circuit_id) ) {
            this.data.circuit_id= circuit_id;
        }

        if (this.data){
            console.log(this.data);
            return;
        }
		// we don't have a cookie and we're not at the workgroups page and we're not in the admin
		// section, so kick them back to workgroups
		if (! location.href.match(/action=workgroups/) && ! location.href.match(/admin/)){
		    location.href = "?action=workgroups";
		}

  };

  this.clear = function(workgroup_too){

      var id   = this.data.workgroup_id;
      var name = this.data.workgroup_name;

      this.data = {};

      // if we're only flushing data, keep the workgroup info
      if (! workgroup_too){
	  this.data.workgroup_id   = id;
	  this.data.workgroup_name = name;
      }

      this.save();
  }

  this.save = function(){
		var expires = new Date();
		expires.setDate(expires.getDate() + 1);
		document.cookie = "data=" + encodeURIComponent(JSON.stringify(this.data)) + ";path=/;expires=" + expires.toUTCString();
  }

  return this;
}

var session = new Cookie();

session.load();

YAHOO.util.Event.onDOMReady(function(){
	if (session.data && session.data.workgroup_name){
	    YAHOO.util.Dom.get("active_workgroup_name").innerHTML = session.data.workgroup_name;
	}


	// we can't select a path in interdomain mode, we need to make sure those options are unavailable
	if (session.data.interdomain == 1){

	    var ids = ["Primary_Path_breadcrumb", "Backup_Path_breadcrumb"];

	    for (var i = 0; i < ids.length; i++){
		YAHOO.util.Dom.get(ids[i]).className = "disabled_breadcrumb";
	    }

	    YAHOO.util.Dom.get("Endpoints_breadcrumb").href = "?action=interdomain";

	}

    });


</script>
