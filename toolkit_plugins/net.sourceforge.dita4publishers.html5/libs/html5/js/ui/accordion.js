(function (d4p) {
	
	d4p.ui.accordion = function (obj) {
		obj.accordion({
			header: '> div.section > h2',
			autoHeight: false // required for Safari
		});		
	};

})(d4p);