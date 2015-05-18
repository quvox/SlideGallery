var pdfs = {};
var pdf_to_open = [];
var id_for_largewin = 0;
var should_reload = false;
var loaded = false;
var fileToUpload = null;

$(function() {
	loaded = true;

	PDFJS.workerSrc = BASE_URL+"dep/javascripts/pdf.worker.js";
	PDFJS.cMapUrl = BASE_URL+"dep/cmaps/";
	PDFJS.cMapPacked = true;

	for (var i=0; i<pdf_to_open.length; i++) {
		if (pdf_to_open[i] == 0) continue;
		openPDF(pdf_to_open[i]);
	}

	$("[data-toggle=tooltip]").tooltip({
		placement: 'bottom'
	});
	$('[data-tooltip="true"]').tooltip({
		placement: 'bottom'
	});

	$('#keywords').keypress(function(e) {
	    if (e.which == '13') {
	        narrowDownByKeyword();
	    }
	});

	/** upload modal window */
	$(document).on('hide.bs.modal', '#uploadModal', function () {
		$("#nodisplayupload").html('<input type="file" id="fileselection" name="filename" value="" style="display:none;"/>');
		$("#filename").val("");
		$(':text[name="titlename"]').val("");
		$(':text[name="tags"]').val("");
		$(':text[name="user"]').val("");
		$(':text[name="pass"]').val("");
	});
	
	// drag and drop
	$("#dropbox").bind("drop", function (event) {
		event.preventDefault();
		fileToUpload = event.originalEvent.dataTransfer.files[0];
		$("#filename").text(fileToUpload.name);
	}).bind("dragenter", function () {
        return false;
    })
    .bind("dragover", function () {
        return false;
    });
    
    // file selection
    $("#fileselection").on('change', function() {
    	fileToUpload = $(this).prop('files')[0];
		$("#filename").val(fileToUpload.name);
    });

	/** edit modal window */
	$(document).on('hide.bs.modal', '#editModal', function () {
		$("#editModal").find(':text[name="titlename"]').val("");
		$("#editModal").find(':text[name="tags"]').val("");
		$("#editModal").find(':text[name="user"]').val("");
		$("#editModal").find(':text[name="pass"]').val("");
		fileToUpload = null;
	});
});

function openPDF(id) {
	if (!loaded) {
		pdf_to_open.push(id);
		return;
	}
	var url = getURL(id);
	if (id == 0 || id == -1) url = getURL(id_for_largewin);
	PDFJS.getDocument(BASE_URL+url).then(function (pdf) {
		var u = url;
		if (id == 0) {
			u = "large";
		} else if (id == -1) {
			u = "middle";
		}
		pdfs[u] = {};
		pdfs[u].pdf = pdf;
		pdfs[u].scale = -1;
		pdfs[u].rendering = false;
		pdfs[u].pageNumPending = 0;
		renderPage(id, 1);
	});
}

function renderPage(id, num) {
	var url = getURL(id);
	if (pdfs[url].rendering) {
		pdfs[url].pageNumPending = num;
		return;
	}
	pdfs[url].num = num;
    pdfs[url].pdf.getPage(num).then(function (page) {
		pdfs[url].rendering = true;
		var $canvas;
		if (url == "large") {
        	$canvas = $('#large-canvas');
		} else if (url == "middle") {
			$canvas = $('#middle-canvas');
        } else {
	        $canvas = $('#the-canvas_'+id);
	    }
        var canvas = $canvas.get(0);
        var context = canvas.getContext("2d");

		if (pdfs[url].scale == -1) {
			if (url != "large") {
		    	var scaleX = canvas.width/page.getViewport(1).width;
		    	var scaleY = canvas.height/page.getViewport(1).height;
				var scale = scaleX;
				if (scaleX > scaleY) scale = scaleY;
				pdfs[url].scale = scale;
			} else {
				canvas.width = page.getViewport(1).width;
				canvas.height = page.getViewport(1).height;
				var viewport = page.getViewport(1);
				pdfs[url].scale = 1;
			}
		}
		var viewport = page.getViewport(pdfs[url].scale);

        var renderContext = {
            canvasContext: context,
            viewport: viewport,
        };
        var task = page.render(renderContext);
        task.promise.then(function () {
        	pdfs[url].rendering = false;
        	var n = pdfs[url].pageNumPending;
        	if (n > 0) {
	        	pdfs[url].pageNumPending = 0;
	        	renderPage(id, n);
        	}
        });
    });
}

/**
 * Returns scale factor for the canvas. It makes sense for the HiDPI displays.
 * @return {Object} The object with horizontal (sx) and vertical (sy)
                    scales. The scaled property is set to false if scaling is
                    not required, true otherwise.
 */
function getOutputScale(ctx) {
  var devicePixelRatio = window.devicePixelRatio || 1;
  var backingStoreRatio = ctx.webkitBackingStorePixelRatio ||
                          ctx.mozBackingStorePixelRatio ||
                          ctx.msBackingStorePixelRatio ||
                          ctx.oBackingStorePixelRatio ||
                          ctx.backingStorePixelRatio || 1;
  var pixelRatio = devicePixelRatio / backingStoreRatio;
  return {
    sx: pixelRatio,
    sy: pixelRatio,
    scaled: pixelRatio !== 1
  };
}

function getURL(id) {
	if (id == 0) return "large";
	if (id == -1) return "middle";
	return "pdf/"+id+".pdf";
}


function pageNext(id) {
	var url = getURL(id);
	var page = pdfs[url].num;
	if (page+1 <= pdfs[url].pdf.numPages) {
		renderPage(id, page+1);
	}
}

function pagePrev(id) {
	var page = pdfs[getURL(id)].num;
	if (page-1 > 0) {
		renderPage(id, page-1);
	}
}

function downloadFile(id) {
	open(BASE_URL+"gallery/download_file?slideid="+id, "download");
}


/**
 * Modal window for uploading a slide file
 */
function openUploadModal() {
	should_relord = false;
}

function closeUploadModal() {
	if (should_reload) location.href=BASE_URL+"gallery/index";
}

function uploadFile() {
	var title = $("#uploadModal").find(':text[name="titlename"]').val();
	var tag = $("#uploadModal").find(':text[name="tags"]').val();
	var user = $("#uploadModal").find(':text[name="user"]').val();
	var pass = $("#uploadModal").find(':text[name="pass"]').val();
	if (fileToUpload == null) {
		alert("A file must be selected.");
		return;
	}
	if (title == "" || title == null || tag == "" || tag == null || user == "" || user == null) {
		alert("Title, Tag and User are mandatory options.");
		return;
	}
	var fd = new FormData();
	fd.append("file", fileToUpload, fileToUpload.name);
	fd.append("title", title);
	fd.append("tags", tag);
	fd.append("user", user);
	fd.append("pass", pass);
	fd.append("fileupload",1);

	var l = Ladda.create(document.querySelector('#upload-button'));
	l.start();
	$.ajax({
		url: BASE_URL+"gallery/upload_file",
		cache: false,
		method: 'POST',
		contentType: false,
		processData: false,
		data: fd,
		dataType: 'json',
		success: function (data, textStatus,xhr) {
			if (!data.success) {
				alert(data.reason);
				return;
			}
			should_reload = true;
			closeUploadModal();
		},
		complete: function(xhr, textStatus) {
			l.stop();
		}
	});
}


/**
 * Modal window for slide show
 */
function showLargeWindow(id) {
	id_for_largewin = id;
	$("#slideViewModal").modal();
	openPDF(0);
}


/**
 * Modal window for editing (updating) a slide info
 */
function openEditModal(id) {
	should_reload = false;
	id_for_largewin = id;
	$.ajax({
		url: BASE_URL+"gallery/get_slide_info",
		cache: false,
		method: 'POST',
		data: {'slideid': id},
	});
	openPDF(-1);
}

function closeEditModal() {
	pdfs['middle'] = null;
	if (should_reload) location.href=BASE_URL+"gallery/index";
}

function updateSlide() {
	var id = $("#editModal").find(':hidden[name="slideid"]').val();
	var title = $("#editModal").find(':text[name="titlename"]').val();
	var tag = $("#editModal").find(':text[name="tags"]').val();
	var user = $("#editModal").find(':text[name="user"]').val();
	var pass = $("#editModal").find(':text[name="pass"]').val();
	var l = Ladda.create(document.querySelector('#update-button'));
	l.start();
	$.ajax({
		url: BASE_URL+"gallery/update_slide",
		cache: false,
		type: "POST",
		data: {
			'slideid': id,
			'title': title,
			'tags': tag,
			'user': user,
			'pass': pass
		},
		dataType: 'json',
		success: function(data, textStatus,xhr) {
			if (!data.success) {
				alert(data.reason);
				return;
			} else {
				should_reload = true;
				closeEditModal();
			}
		},
		error: function(xhr, textStatus, errorThrown) {
		},
		complete: function(xhr, textStatus) {
			l.stop();
		}
	});
}

function deleteSlide() {
	if (! confirm("Are you sure to delete the file?")) {
		return;
	}
	var id = $("#editModal").find(':hidden[name="slideid"]').val();
	var user = $("#editModal").find(':text[name="user"]').val();
	var pass = $("#editModal").find(':text[name="pass"]').val();
	var l = Ladda.create(document.querySelector('#delete-button'));
	l.start();
	$.ajax({
		url: BASE_URL+"gallery/delete_slide",
		cache: false,
		type: "POST",
		data: {
			'slideid': id,
			'user': user,
			'pass': pass
		},
		dataType: 'json',
		success: function(data, textStatus,xhr) {
			if (!data.success) {
				alert(data.reason);
				return;
			} else {
				should_reload = true;
				closeEditModal();
			}
		},
		error: function(xhr, textStatus, errorThrown) {
		},
		complete: function(xhr, textStatus) {
			l.stop();
		}
	});
}

function narrowDownByTag(tag) {
	$.ajax({
		url: BASE_URL+"gallery/get_slides",
		cache: false,
		type: "POST",
		data: {
			'tag': tag,
		}
	});
}

function narrowDownByUser(u) {
	$.ajax({
		url: BASE_URL+"gallery/get_slides",
		cache: false,
		type: "POST",
		data: {
			'user': u,
		}
	});
}

function narrowDownByKeyword() {
	if ($('#keywords').val() == "") return;
	$.ajax({
		url: BASE_URL+"gallery/get_slides",
		cache: false,
		type: "POST",
		data: {
			'keyword': $('#keywords').val()
		}
	});
}