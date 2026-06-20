---
title: "Contact"
type: "page"
_build: { list: never, render: always }
---
---
<div class="contact-grid">

  <div class="contact-form-wrap">
    <h3>Send me a message 📬</h3>
    <form action="https://formspree.io/f/YOUR_FORM_ID" method="POST" class="contact-form">
      <input type="text" name="_gotcha" style="display:none">
      <label for="name">Your name</label>
      <input id="name" name="name" type="text" required>
      <label for="email">Your email</label>
      <input id="email" name="_replyto" type="email" required>
      <label for="message">Message</label>
      <textarea id="message" name="message" rows="6" required></textarea>
      <input type="hidden" name="_subject" value="Website contact">
      <button type="submit">Send</button>
    </form>
  </div>

  <div class="contact-map-wrap">
    <h3>Elsewhere</h3>
    <p>I am easiest to reach by email or through my professional profiles.</p>
    <p>
      <a href="mailto:mail@alonsopg.com">mail@alonsopg.com</a><br>
      <a href="https://www.linkedin.com/in/alonsopg/" target="_blank" rel="noopener noreferrer">LinkedIn</a><br>
      <a href="https://github.com/alonsopg" target="_blank" rel="noopener noreferrer">GitHub</a><br>
      <a href="https://scholar.google.com/citations?user=iIoiAGQAAAAJ" target="_blank" rel="noopener noreferrer">Google Scholar</a>
    </p>
  </div>

</div>
