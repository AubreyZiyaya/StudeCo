import { signIn, signUp } from "./supabase-client.js";

const authMessage = document.getElementById("auth-message");

function setMessage(text, isError = false) {
  authMessage.textContent = text;
  authMessage.style.color = isError ? "#d6465f" : "#1a8f5a";
}

document.addEventListener("DOMContentLoaded", () => {
  const loginForm = document.getElementById("login-form");
  const registerForm = document.getElementById("register-form");

  if (loginForm) {
    loginForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      const formData = new FormData(loginForm);
      const email = String(formData.get("email") || "").trim();
      const password = String(formData.get("password") || "");

      const { data, error } = await signIn(email, password);
      if (error) {
        setMessage(error.message, true);
        return;
      }

      setMessage("Signed in successfully.");
      setTimeout(() => {
        window.location.href = "app/feed.html";
      }, 600);
    });
  }

  if (registerForm) {
    registerForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      const formData = new FormData(registerForm);
      const payload = {
        email: String(formData.get("email") || "").trim(),
        password: String(formData.get("password") || ""),
        display_name: String(formData.get("display_name") || "").trim(),
        education_level: String(formData.get("education_level") || "secondary"),
      };

      if (!payload.email || !payload.password || !payload.display_name) {
        setMessage("Please complete all required fields.", true);
        return;
      }

      const { data, error } = await signUp(payload);
      if (error) {
        setMessage(error.message, true);
        return;
      }

      setMessage("Account created. Check your email to verify your account.");
    });
  }
});
