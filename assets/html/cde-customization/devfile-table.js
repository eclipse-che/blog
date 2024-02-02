const inputelmements = document.querySelectorAll("input");
const devfiles = document.getElementsByClassName("area");

inputelmements.forEach(function (elem) {
  elem.addEventListener("click", updateValue);
});

function updateValue(e) {
  Array.from(devfiles).forEach((devfile) => (devfile.style.display = "none"));
  document.getElementById(e.target.value).style.display = "block";
}

// hljs.highlightAll();
