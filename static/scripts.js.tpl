var API_ENDPOINT = "${api_url}/${stage_name}/${api_resource}";
var API_KEY = "${api_key}";

// Function to save student data
document.getElementById("savestudent").onclick = function(event) {
    event.preventDefault(); // Prevents automatic form submission

    // Captures field values
    var name = $('#name').val().trim();
    var studentClass = $('#student_class').val().trim();
    var age = $('#age').val().trim();

    if (!name || !studentClass || !age) {
        alert("Please fill in all fields.");
        return;
    }

    var inputData = {
        "name": name,
        "student_class": studentClass,
        "age": age
    };

    // Makes the AJAX request to save the data
    $.ajax({
        url: API_ENDPOINT,
        type: 'POST',
        headers: {
            'x-api-key': API_KEY
        },
        data: JSON.stringify(inputData),
        contentType: 'application/json; charset=utf-8',
        success: function(response) {
            alert("Student Data Saved!");
            // Clear fields after saving
            $('#name').val('');
            $('#student_class').val('');
            $('#age').val('');
        },
        error: function(xhr, status, error) {
        if (xhr.status === 429) {
            alert("Too many requests. Please try again in another day.");
        } else {
            alert("Error saving student data: " + xhr.responseText);
        }
        console.log('Error details:', xhr.responseText);
    }
    });
};

// Function to search for all students
document.getElementById("getstudents").onclick = function(event) {
    event.preventDefault(); // Prevents automatic form submission

    $.ajax({
        url: API_ENDPOINT,
        type: 'GET',
        headers: {
            'x-api-key': API_KEY
        },
        contentType: 'application/json; charset=utf-8',
        success: function(response) {
            $('#studentTable tbody').empty(); // Clear the table before updating
            jQuery.each(response, function(i, data) {
                $("#studentTable tbody").append("<tr> \
                    <td>" + data['name'] + "</td> \
                    <td>" + data['student_class'] + "</td> \
                    <td>" + data['age'] + "</td> \
                    </tr>");
            });
        },
        error: function(xhr, status, error) {
        if (xhr.status === 429) {
            alert("Too many requests. Please try again in another day.");
        } else {
            alert("Error saving student data: " + xhr.responseText);
        }
        console.log('Error details:', xhr.responseText);
    }
    });
};
