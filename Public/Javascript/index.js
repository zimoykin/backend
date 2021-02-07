

function loadPage () {
    
    const menu = document.getElementById("menu")
    const login = document.getElementById("login");
    
    menu.style.width = "0px";
    login.style.width = "0px";
    document.getElementById("mainTitle").style.opacity = 1;
    setTitleVisible();
    
    window.addEventListener('scroll', function() {
        setTitleVisible ()
    });
}

function loadPagePost (image_src) {
    
    const menu = document.getElementById("menu");
    const login = document.getElementById("login");
    
    menu.style.width = "0px";
    login.style.width = "0px";
    
    document.getElementById("mainTitle").style.opacity = 1;
    
    window.addEventListener('scroll', function() {
        setTitleVisible ()
    });
    
    document.getElementById("imageselect").style.backgroundImage = 'url(' + image_src + ')';
}

function setTitleVisible () {
    
    const centertitleOntop = document.getElementById("centertitleOntop");
    const footer = document.getElementById("footer")
    
    footer.style.opacity = 0;
    footer.style.transition = "all 1s";
    footer.style.color = "blanchedalmond";
    footer.style.backgroundColor = "Seagreen";
    
    if ((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
        footer.style.opacity = 1;
    }
    
    var opacity = pageYOffset / 200
    
    if (opacity > 1) {
        opacity = 1
    }
    
    if ( menu.style.width == "0px") {
        centertitleOntop.style.opacity = opacity;
    } else {
        centertitleOntop.style.opacity = 0;
    }
    
    document.getElementById("mainTitle").style.opacity = 1 - opacity;
    
}

function loginTouched (image_src) {
    
    console.log("loginTouched")
    
    const login = document.getElementById("login")
       
       if ( login.style.width == "0px") {
           login.style.width = window.screen.width/3 + "px";
       } else {
           login.style.width = "0px";
       }
       
    document.getElementById("ava").style.backgroundImage = 'url(' + image_src + ')';
    
}

function hideMenu () {
    openNav();
}

function loadContentPage () {
    
    console.log("hell yeah");
    
}

function validate(e) {
   
    var keycode = (e.which) ? e.which : e.keyCode;
    var phn = document.getElementById('bidarea');
     
    if ((keycode < 48 || keycode > 57) && keycode !== 13) {
        e.preventDefault();
        return false;
    }
}


function openNav () {
    
    const menu = document.getElementById("menu")
    
    if ( menu.style.width == "0px") {
        menu.style.width = window.screen.width/3 + "px";
    } else {
        menu.style.width = "0px";
    }
    
    setTitleVisible();
    
}


function onSignIn(googleUser) {
  var profile = googleUser.getBasicProfile();
  console.log('ID: ' + profile.getId()); // Do not send to your backend! Use an ID token instead.
  console.log('Name: ' + profile.getName());
  console.log('Image URL: ' + profile.getImageUrl());
  console.log('Email: ' + profile.getEmail()); // This is null if the 'email' scope is not present.
}


function SearchBarByKey(input) {
    var input, filter, ul, li, a, i, txtValue;
    
    filter = input.value.toUpperCase();
    
    ul = document.getElementById("myUL");
    li = ul.getElementsByTagName("li");
    
    for (i = 0; i < li.length; i++) {
        a = li[i].getElementsByTagName("p")[0];
        txtValue = a.textContent || a.innerText;
        if (txtValue.toUpperCase().indexOf(filter) > -1) {
            li[i].style.display = "";
        } else {
            li[i].style.display = "none";
        }
    }
}


function SelectedThisCountry (countryTitle, country) {
    
    var selectedCountry = document.getElementById("countryLabel");
    selectedCountry.innerText = countryTitle
    
    var countryid = document.getElementById("countryId");
    countryid.value = country;
    
}
